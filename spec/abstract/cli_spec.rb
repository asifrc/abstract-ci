require './lib/abstract/cli'

module Abstract
  describe CLI do
    describe '#create' do
      before(:each) do
        allow_any_instance_of(Abstract::Backend::GoCD).to receive(:create)
        allow_any_instance_of(Abstract::Backend::GoCD)
          .to receive(:wait_until_connected)
        @cli = CLI.new
      end
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
  end
end
