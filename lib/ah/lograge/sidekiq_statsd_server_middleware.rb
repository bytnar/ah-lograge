require 'sidekiq/api'
require 'statsd'

module Ah
  module Lograge
    class SidekiqStatsdServerMiddleware
      def initialize(options=nil)
        @statsd = options[:statsd]
      end

      def call(_worker, msg, queue)
        start_time = time_now
        batch = Statsd::Batch.new(@statsd)
        worker_name = get_worker_name(msg)
        yield
        batch.increment(prefix(worker_name, 'success'))
      rescue => e
        batch.increment(prefix(worker_name, 'failure'))
        raise e
      ensure
        batch.timing(prefix(worker_name, 'duration'), time_now - start_time)
        queue_stats(batch, queue)
        send_global_stats(batch)
        batch.flush
      end

      private

      def get_worker_name(msg)
        if msg['class'] == 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper' && msg['args'] && msg['args'].size > 0
          msg['args'].first['job_class'].gsub('::', '.')
        else
          msg['class'].gsub('::', '.')
        end
      rescue
        msg['class'].to_s.gsub('::', '.')
      end

      def send_global_stats(batch)
        stats = Sidekiq::Stats.new
        batch.gauge(prefix('processed'), stats.processed)
        batch.gauge(prefix('failed'), stats.failed)
        batch.gauge(prefix('scheduled'), stats.scheduled_size)
        batch.gauge(prefix('retry'), stats.retry_size)
        batch.gauge(prefix('dead'), stats.dead_size)
        batch.gauge(prefix('enqueued'), stats.enqueued)
        batch.gauge(prefix('processes'), stats.processes_size)
        batch.gauge(prefix('workers'), stats.workers_size)
      end

      def queue_stats(batch, queue_name)
        queue = Sidekiq::Queue.new(queue_name)
        batch.gauge(prefix(queue_name, 'size'), queue.size)
        batch.gauge(prefix(queue_name, 'latency'), queue.latency)
      end

      def prefix(*args)
        ['sidekiq', *args].compact.join('.')
      end

      def time_now
        Process.respond_to?(:clock_gettime) ? Process.clock_gettime(Process::CLOCK_MONOTONIC) : Time.now
      end
    end
  end
end
