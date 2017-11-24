module Ah
  module Lograge
    class CustomOptionsPreparer
      NOT_LOGGED_PARAMS = %w(controller action format utf8).freeze

      def self.prepare_custom_options(event)
        params = {
          params: prepare_params(event.payload[:params]),
          exception: event.payload[:exception],
          exception_object: event.payload[:exception_object]
        }

        params.merge!(Ah::Lograge.additional_custom_entries_block.(event)) if Ah::Lograge.additional_custom_entries_block

        params
      end

      def self.prepare_params(event_params)
        params = event_params.except(*NOT_LOGGED_PARAMS)
        if ::Ah::Lograge.filter_params_block
          ::Ah::Lograge.filter_params_block.(params)
        end

        serializable?(params, event_params) ? params : { error: 'params not serializable' }
      end

      def self.serializable?(params, full_params = {})
        deep_encode(nil, params)
        params.to_json
        true
      rescue StandardError => e
        if defined? Airbrake
          Airbrake.notify(e, error_message: 'params not serializable', params: full_params.slice("controller", "action"))
        else
          Rails.logger.error(e)
        end
        false
      end

      def self.deep_encode(parent, hash)
        hash.each do |key, value|
          encode_value(hash, key, value)
        end
      end

      def self.encode_value(hash, key, value)
        if value.is_a?(Hash)
          deep_encode(key, value)
        elsif value.is_a?(Array)
          value.each_with_index do |val,idx|
            encode_value(value, idx, val)
          end
        elsif value.is_a?(ActionDispatch::Http::UploadedFile)
          hash[key] = {
            type: 'ActionDispatch::Http::UploadedFile',
            name: encode_string_proper_utf8(value.original_filename),
            size: value.size,
            content_type: value.content_type
          }
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
