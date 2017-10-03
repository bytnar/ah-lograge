require 'ah/lograge/sidekiq_statsd_server_middleware'

describe Ah::Lograge::SidekiqStatsdServerMiddleware do
  let(:statsd) { double(Statsd) }
  let(:batch) { double(Statsd::Batch) }

  let(:stats) { double(Sidekiq::Stats) }
  let(:queue) { double(Sidekiq::Queue) }

  let(:worker) { double("ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper") }
  let(:queue_name) { 'some_queue'}
  let(:job_name) { 'SomeJob' }
  let(:msg) do
    {
      "class" => "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
      "queue" => queue_name,
      "description" => "",
      "args" =>
        [
          {
            "job_class" => job_name,
            "job_id" => "e4f50010-8ce7-47fa-a3aa-cc22a284ce3c",
            "queue_name" => queue_name,
            "arguments" => []
          }
        ],
      "retry" => true,
      "jid" => "cde794108ba53bcde5d53e0c",
      "created_at" => 1506935974.360817,
      "enqueued_at" => 1506935974.360885
    }
  end

  subject { described_class.new({ statsd: statsd }) }

  before do
    allow(Statsd::Batch).to receive(:new).with(statsd).and_return(batch)
    allow(batch).to receive(:increment)
    allow(batch).to receive(:timing)
    allow(batch).to receive(:gauge)
    allow(batch).to receive(:flush)
    allow(Sidekiq::Stats).to receive(:new).and_return(stats)
    allow(stats).to receive(:processed)
    allow(stats).to receive(:failed)
    allow(stats).to receive(:scheduled_size)
    allow(stats).to receive(:retry_size)
    allow(stats).to receive(:dead_size)
    allow(stats).to receive(:enqueued)
    allow(stats).to receive(:processes_size)
    allow(stats).to receive(:workers_size)
    allow(Sidekiq::Queue).to receive(:new).with(queue_name).and_return(queue)
    allow(queue).to receive(:size)
    allow(queue).to receive(:latency)
  end

  context 'on success' do
    it 'sets worker name according to class field if class is different than ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper' do
      msg['class'] = 'SomeOtherJob'
      expect(batch).to receive(:increment).with("sidekiq.SomeOtherJob.success")

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'sets worker name according to class field if args are nil' do
      msg['args'] = nil
      expect(batch).to receive(:increment).with("sidekiq.ActiveJob.QueueAdapters.SidekiqAdapter.JobWrapper.success")

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'sets worker name according to class field if args are empty list' do
      msg['args'] = []
      expect(batch).to receive(:increment).with("sidekiq.ActiveJob.QueueAdapters.SidekiqAdapter.JobWrapper.success")

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'sets worker name according to stringfied class field on any error' do
      msg['class'] = Ah::Lograge::SidekiqStatsdServerMiddleware
      expect(batch).to receive(:increment).with("sidekiq.Ah.Lograge.SidekiqStatsdServerMiddleware.success")

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'sets global stats gauges' do
      expect(stats).to receive(:processed).and_return(11)
      expect(stats).to receive(:failed).and_return(12)
      expect(stats).to receive(:scheduled_size).and_return(13)
      expect(stats).to receive(:retry_size).and_return(14)
      expect(stats).to receive(:dead_size).and_return(15)
      expect(stats).to receive(:enqueued).and_return(16)
      expect(stats).to receive(:processes_size).and_return(1)
      expect(stats).to receive(:workers_size).and_return(2)
      expect(batch).to receive(:gauge).with('sidekiq.processed', 11)
      expect(batch).to receive(:gauge).with('sidekiq.failed', 12)
      expect(batch).to receive(:gauge).with('sidekiq.scheduled', 13)
      expect(batch).to receive(:gauge).with('sidekiq.retry', 14)
      expect(batch).to receive(:gauge).with('sidekiq.dead', 15)
      expect(batch).to receive(:gauge).with('sidekiq.enqueued', 16)
      expect(batch).to receive(:gauge).with('sidekiq.processes', 1)
      expect(batch).to receive(:gauge).with('sidekiq.workers', 2)

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'sets queue stats gauges' do
      expect(queue).to receive(:size).and_return(11)
      expect(queue).to receive(:latency).and_return(123.0)
      expect(batch).to receive(:gauge).with("sidekiq.#{queue_name}.size", 11)
      expect(batch).to receive(:gauge).with("sidekiq.#{queue_name}.latency", 123.0)

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'sets timing' do
      expect(batch).to receive(:timing).with("sidekiq.#{job_name}.duration", kind_of(Numeric))

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'increments success counter' do
      expect(batch).to receive(:increment).with("sidekiq.#{job_name}.success")

      subject.call(worker, msg, queue_name) { 'success message' }
    end

    it 'flushes batch' do
      expect(batch).to receive(:flush)

      subject.call(worker, msg, queue_name) { 'success message' }
    end
  end

  context 'on failure' do
    it 'sets global stats gauges' do
      expect(stats).to receive(:processed).and_return(11)
      expect(stats).to receive(:failed).and_return(12)
      expect(stats).to receive(:scheduled_size).and_return(13)
      expect(stats).to receive(:retry_size).and_return(14)
      expect(stats).to receive(:dead_size).and_return(15)
      expect(stats).to receive(:enqueued).and_return(16)
      expect(stats).to receive(:processes_size).and_return(1)
      expect(stats).to receive(:workers_size).and_return(2)
      expect(batch).to receive(:gauge).with('sidekiq.processed', 11)
      expect(batch).to receive(:gauge).with('sidekiq.failed', 12)
      expect(batch).to receive(:gauge).with('sidekiq.scheduled', 13)
      expect(batch).to receive(:gauge).with('sidekiq.retry', 14)
      expect(batch).to receive(:gauge).with('sidekiq.dead', 15)
      expect(batch).to receive(:gauge).with('sidekiq.enqueued', 16)
      expect(batch).to receive(:gauge).with('sidekiq.processes', 1)
      expect(batch).to receive(:gauge).with('sidekiq.workers', 2)

      expect { subject.call(worker, msg, queue_name) { raise "some error" } }.to raise_error(RuntimeError)
    end

    it 'sets queue stats gauges' do
      expect(queue).to receive(:size).and_return(11)
      expect(queue).to receive(:latency).and_return(123.0)
      expect(batch).to receive(:gauge).with("sidekiq.#{queue_name}.size", 11)
      expect(batch).to receive(:gauge).with("sidekiq.#{queue_name}.latency", 123.0)

      expect { subject.call(worker, msg, queue_name) { raise "some error" } }.to raise_error(RuntimeError)
    end

    it 'sets timing' do
      expect(batch).to receive(:timing).with("sidekiq.#{job_name}.duration", kind_of(Numeric))

      expect { subject.call(worker, msg, queue_name) { raise "some error" } }.to raise_error(RuntimeError)
    end

    it 'increments failure counter' do
      expect(batch).to receive(:increment).with("sidekiq.#{job_name}.failure")

      expect { subject.call(worker, msg, queue_name) { raise "some error" } }.to raise_error(RuntimeError)
    end

    it 'flushes batch' do
      expect(batch).to receive(:flush)

      expect { subject.call(worker, msg, queue_name) { raise "some error" } }.to raise_error(RuntimeError)
    end
  end
end
