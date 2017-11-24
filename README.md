# Ah::Lograge
Common initializers for logging and monitoring across Airhelp Rails projects:
* lograge - for readable rails http logs
* sidekiq statsd middleware - for sidekiq stats

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'ah-lograge'
```

And then execute:
```bash
$ bundle
```

## Lograge

### Usage
Just install it. You can pass env variable `DISABLE_LOGRAGE` to disable it.

### Custom params filtering
add `config/initializers/lograge.rb` to your app with following:
```ruby
Ah::Lograge.filter_params do |params|
  params.delete("unwanted")
end
```

### Custom payload entries adding

in `config/initializers/lograge.rb` add something like:

```ruby
Ah::Lograge.additional_custom_entries do |event|
  { something: event.payload[:something] }
end
```

## Sidekiq Statsd Middleware
The middleware requires sidekiq and statsd-ruby to operate (it needs to be provided in application gemfile).
It will report various sidekiq metrics via statsd. There is a penalty: job execution duration will be 0.08s longer (we can live with that).
If statsd host fails it will not interrupt normal sidekiq operation.

### Usage

```ruby
require 'ah/lograge/sidekiq_statsd_server_middleware'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Ah::Lograge::SidekiqStatsdServerMiddleware, statsd: Statsd.new(Settings.statsd_host)
  end
end
```


## Contributing
Just create a PR & ping #dev-room or our developers email.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
