require 'ostruct'

describe Ah::Lograge::CustomOptionsPreparer do
  # The real trick here is that Tempfile is trying to serialize it's contents
  # this test is about if we catch UploadedFIle and generate it's json manually
  describe '.serializable?' do
    let(:crazy_character) { "\x89".force_encoding('ASCII-8BIT') }
    let(:tempfile) { Tempfile.new('uploaded_file').tap { |f| f.write(crazy_character); f.seek(0) } }
    let(:params) do
      {
        attachment: ActionDispatch::Http::UploadedFile.new(
          tempfile: tempfile, filename: "some_temp_file.ext", type: "text/plain"
        )
      }
    end
    it 'forces params to be serializable' do
      expect(described_class.serializable?(params)).to be_truthy
      expect{ params.to_json }.not_to raise_exception
      expect(params).to eq(
        attachment: {
           type: "ActionDispatch::Http::UploadedFile",
           name: "some_temp_file.ext",
           size: 1,
           content_type: "text/plain"
        }
      )
    end
    describe 'array params' do
      let(:crazy_character) { "\x89".force_encoding('ASCII-8BIT') }
      let(:tempfile) { Tempfile.new('uploaded_file').tap { |f| f.write(crazy_character); f.seek(0) } }
      let(:uploaded_file_param) do
        ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile, filename: "some_temp_file.ext", type: "text/plain"
        )
      end
      let(:params) do
        {
            language: ['pl', 'en', uploaded_file_param]
        }
      end
      it 'handles UploadedFile inside Array' do
        expect(described_class.serializable?(params)).to be_truthy
        expect(params[:language]).to include('pl', 'en', a_kind_of(Hash))
        expect(params[:language].last).to include(type: 'ActionDispatch::Http::UploadedFile')
      end
    end
    describe 'bad encoded file name' do
      let(:params) do
        {
          attachment: ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile, filename: "some_temp_file#{ crazy_character }.ext", type: "text/plain"
          )
        }
      end
      specify do
        expect(described_class.serializable?(params)).to be_truthy
        expect(params[:attachment][:name]).to eq('some_temp_file?.ext')
      end
    end
    describe 'ActionController::Parameters' do
      let(:params) { ActionController::Parameters.new(super()) }
      specify do
        expect(described_class.serializable?(params)).to be_truthy
        expect(params).to be_kind_of(ActionController::Parameters)
        expect { params.to_json }.not_to raise_exception
      end
    end
    describe 'Airbrake logging' do
      let(:params) { super().merge(invalid: crazy_character) }
      specify do
        stub_const("Airbrake", Class)
        full_params = { "controller"=>"a", "action"=>"b" }
        expect(Airbrake).to receive(:notify).with(any_args, a_hash_including(params: full_params))
        expect(described_class.serializable?(params, full_params)).to be_falsey
      end
    end
  end

  describe '.prepare_custom_options' do
    let(:additional_entries) { ->(event) { { something: event.payload[:name] } } }
    let(:event) { OpenStruct.new(payload: payload) }
    let(:payload) { { params: { test: true }, name: 'ugabuga' } }

    subject { described_class.prepare_custom_options(event) }

    it 'prepares logging option by default' do
      expect(subject).to eq({
        params: { test: true },
        exception: nil,
        exception_object: nil
      })
    end

    context 'when some additional payload entries are configured to be added' do
      before { allow(Ah::Lograge).to receive(:additional_custom_entries_block).and_return(additional_entries) }

      it 'uses provided block with event object' do
        expect(additional_entries).to receive(:call).with(event).and_return({})
        subject
      end

      it 'has proper paylod' do
        expect(subject).to eq({
          params: { test: true },
          exception: nil,
          exception_object: nil,
          something: 'ugabuga'
        })
      end
    end
  end
end
