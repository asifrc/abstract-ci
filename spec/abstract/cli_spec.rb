require './lib/abstract/cli'

module Abstract
  describe CLI do
    describe '#create' do
      it 'should create a GoCD backend' do
        expect_any_instance_of(Abstract::Backend::GoCD).to receive(:create)
        cli = CLI.new
        cli.create
      end
    end
  end
end
