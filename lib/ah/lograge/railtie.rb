module Ah
  module Lograge
    class Railtie < ::Rails::Railtie
      initializer 'ah-lograge.setup_logging' do |app|
        lograge_disabled = ENV['DISABLE_LOGRAGE'] || false
        app.config.lograge.enabled = !lograge_disabled
        app.config.lograge.formatter = ::Lograge::Formatters::Logstash.new
        app.config.lograge.custom_options = lambda do |event|
          Ah::Lograge::CustomOptionsPreparer.prepare_custom_options(event)
        end
      end
    end
  end
end
