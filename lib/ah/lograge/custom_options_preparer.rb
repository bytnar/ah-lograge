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
        filter_out_file_params!(params)

        serializable?(params) ? params : { error: 'params not serializable' }
      end

      # Unfortunatelly ActionDispatch::Http::UploadedFile is not json serializable
      # This method filters it out from params
      def self.filter_out_file_params!(params)
        params['travel_document'] = params['travel_document'].except('document') if params.key?('travel_document')
        params['internal_document'] = params['internal_document'].except('document') if params.key?('internal_document')
        params['attachment'] = params['attachment'].except('document') if params.key?('attachment')
      end

      def self.serializable?(params)
        params.to_json
        true
      rescue StandardError => e
        Airbrake.notify(e, error_message: 'params not serializable')
        false
      end
    end
  end
end
