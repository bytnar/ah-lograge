# ActiveRecord::RecordInvalid doesn't say a thing about a record caused problem, fix that:
module ActiveRecord
  class ActiveRecordError < StandardError
    def to_airbrake
      if @record
        params = { params: { record: @record.attributes } }
        # filter sensitive info
        filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
        filter.filter(params)
      else
        {}
      end
    end
  end
end
