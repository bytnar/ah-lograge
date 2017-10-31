# ActiveRecord::RecordInvalid doesn't say a thing about a record caused problem, fix that:
module ActiveRecord
  class ActiveRecordError < StandardError
    def to_airbrake
      if @record
        { params: { record: @record.attributes } }
      else
        {}
      end
    end
  end
end
