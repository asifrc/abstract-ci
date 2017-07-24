require './spec/spec_helper'
require './lib/abstract/state/yaml_file'

module Abstract
  module State
    describe YamlFile do
      describe '#setup' do
        it 'should create .abstract directory if it does not exist' do
          expect(FileUtils).to receive(:mkdir_p).with('./.abstract')
          state = YamlFile.new
          state.setup
        end
      end
      describe '#update' do
        it 'should save hash as yaml to ./.abstract/state.yml' do
          backend_data = {
            'type' => 'gocd',
            'id' => 'a01b'
          }
          expected_path = './.abstract/state.yml'
          expected_content = "---\nbackend:\n  type: gocd\n  id: a01b\n"
          expect(File).to receive(:write).with(expected_path, expected_content)

          state = YamlFile.new
          state.update 'backend', backend_data
        end
      end
    end
  end
end
