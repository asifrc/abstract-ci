require './lib/abstract/cli'

module Abstract
  describe CLI do
    before(:each) do
      allow_any_instance_of(Abstract::Backend::GoCD).tap do |klass|
        klass.to receive(:create)
        klass.to receive(:destroy)
        klass.to receive(:wait_until_connected)
      end
      @cli = CLI.new
    end
    describe '#create' do
      it 'should create a GoCD backend' do
        expect_any_instance_of(Abstract::Backend::GoCD).to receive(:create)
        @cli.create
      end
      it 'should wait for the GoCD backend to come up' do
        expect_any_instance_of(Abstract::Backend::GoCD)
          .to receive(:wait_until_connected)
        @cli.create
      end
    end
    describe '#destroy' do
      it 'should create a GoCD backend' do
        expect_any_instance_of(Abstract::Backend::GoCD).to receive(:destroy)
        @cli.destroy
      end
    end
  end
end
