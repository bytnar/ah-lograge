module Ah
  module Lograge
    class Railtie < ::Rails::Railtie
      initializer 'ah-lograge.setup_logging' do |app|
        lograge_disabled = if Rails.version >= '4.2'
          ActiveRecord::Type::Boolean.new.type_cast_from_database(ENV['DISABLE_LOGRAGE']) || false
        elsif Rails.version >= '5.0'
          ActiveRecord::Type::Boolean.new.cast(ENV['DISABLE_LOGRAGE']) || false
        else
          [true, 1, "1", "y", "true", "on", "yes"].include?(ENV['DISABLE_LOGRAGE'].to_s.downcase) || false
        end
        app.config.lograge.enabled = !lograge_disabled
        app.config.lograge.formatter = ::Lograge::Formatters::Logstash.new
        app.config.lograge.custom_options = lambda do |event|
          Ah::Lograge::CustomOptionsPreparer.prepare_custom_options(event)
        end
      end
    end
  end
end
