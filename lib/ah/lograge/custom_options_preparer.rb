module Ah
  module Lograge
    class CustomOptionsPreparer
      NOT_LOGGED_PARAMS = %w(controller action format utf8).freeze

      def self.prepare_custom_options(event)
        {
          params: prepare_params(event.payload[:params]),
          exception: event.payload[:exception],
          exception_object: event.payload[:exception_object]
        }
      end

      def self.prepare_params(event_params)
        params = event_params.except(*NOT_LOGGED_PARAMS)
        if ::Ah::Lograge.filter_params_block
          ::Ah::Lograge.filter_params_block.(params)
        end

        serializable?(params) ? params : { error: 'params not serializable' }
      end

      def self.serializable?(params)
        deep_serialize(nil, params)
        params.to_json
        true
      rescue StandardError => e
        if defined? Airbrake
          encoded_params = encode_string_proper_utf8(params.to_s)
          Airbrake.notify(e, error_message: 'params not serializable', params: encoded_params)
        else
          Rails.logger.error(e)
        end
        false
      end

      def self.deep_serialize(parent, hash)
        hash.each do |key, value|
          if value.is_a?(Hash)
            deep_serialize(key, value)
          elsif value.is_a?(Array)
            value.each { |val| deep_serialize(key, val) }
          elsif value.is_a?(ActionDispatch::Http::UploadedFile)
            hash[key] = {
              type: 'ActionDispatch::Http::UploadedFile',
              name: encode_string_proper_utf8(value.original_filename),
              size: value.size,
              content_type: value.content_type
            }
          end
        end
      end

      def self.encode_string_proper_utf8(str)
        str.encode(
          'UTF-8',
          :invalid => :replace,
          :undef => :replace,
          :replace => '?'
        )
      end
    end
  end
end
