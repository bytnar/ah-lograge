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
        params.to_json
        true
      rescue StandardError => e
        if defined? Airbrake
          Airbrake.notify(e, error_message: 'params not serializable')
        else
          Rails.logger.error(e)
        end
        false
      end
    end
  end
end
