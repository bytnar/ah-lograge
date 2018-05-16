describe Ah::Lograge::AuditLogger do
  LOGGER = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

  let(:action) { :get }
  let(:user) do
    double(:user, ah_user_uid: 'ah_user_uid')
  end
  let(:resource_1) { double(:resource, path: 'resource_path', customer_uid: 'customer_uid') }
  let(:app) { 'EXTERNAL_APP_NAME' }
  let!(:logger) { LOGGER }

  before do
    allow(ActiveSupport::TaggedLogging).to receive(:new).and_return(logger)
  end

  describe '.log_resource_action' do
    subject { described_class.log_resource_action(params) }

    context 'resource, action and user provided' do
      let(:params) do 
        {
          resource: resource_1,
          action: action,
          requester: user.ah_user_uid,
          customer_uid: 'customer_uid'
        }
      end

      it 'calls logger with proper attributes' do
        expect(logger).to receive(:info).with({
          audit_requester_uid: user.ah_user_uid,
          audit_action: 'GET',
          audit_request_source: 'self',
          audit_resource: resource_1.as_json,
          audit_customer_uid: resource_1.customer_uid
        })
        subject
      end
    end

    context 'resource, action, user and app provided' do
      let(:params) do 
        {
          resource: resource_1,
          action: action,
          requester: user.ah_user_uid,
          customer_uid: 'customer_uid',
          app: app
        }
      end

      it 'calls logger with proper attributes' do
        expect(logger).to receive(:info)
        subject
      end
    end
  end

  describe '.log_resources_action' do
    let(:resources) { [ resource_1 ] }
    subject { described_class.log_resources_action(params) }
    let(:params) {{ resources: resources, action: action, requester: user.ah_user_uid, customer_uid: 'customer_uid' }} 

    it 'calls log_resource_action on each resource' do
      expect(described_class).to receive(:log_resource_action).exactly(resources.count).times
      subject
    end
  end
end
