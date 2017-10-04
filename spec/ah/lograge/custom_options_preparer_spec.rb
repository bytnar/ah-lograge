describe Ah::Lograge::CustomOptionsPreparer do
  describe '#serializable?' do
    let(:params) do
      { a: "\x89".force_encoding('ASCII-8BIT') }
    end
    it 'forces params to be serializable' do
      # simple call .to_json generates:
      # Encoding::UndefinedConversionError: "\x89" from ASCII-8BIT to UTF-8
      expect(described_class.serializable?(params)).to be_truthy
    end
    describe 'ActionController::Parameters' do
      let(:params) { ActionController::Parameters.new(super()) }
      specify do
        expect(described_class.serializable?(params)).to be_truthy
        expect(params).to be_kind_of(ActionController::Parameters)
        expect(params.to_json).to eq('{"a":"?"}')
      end
    end
  end
end
