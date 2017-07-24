require './spec/spec_helper'
require './lib/abstract/state/yaml_file'

module Abstract
  module State
    describe YamlFile do
      describe '#setup' do
      end
      describe '#load' do
        it 'should return hash from state.yml file' do
          expected_path = './.abstract/state.yml'
          file_content = "---\nbackend:\n  type: gocd\n  id: a01b\n"
          output = StringIO.new file_content
          allow(File).to receive(:open).with(expected_path).and_yield(output)

          state = YamlFile.new
          state_hash = state.load

          expect(state_hash).to include(
            'backend' =>  hash_including(
              'type' => 'gocd',
              'id' => 'a01b'
            )
          )
        end
        it 'should return an empty hash if file is not found' do
          allow(File).to receive(:open).and_raise(Errno::ENOENT)

          state = YamlFile.new
          state_hash = state.load

          expect(state_hash).to eq({})
        end
      end
      describe '#update' do
        it 'should create .abstract directory if it does not exist' do
          expected_path = './.abstract/state.yml'
          output = StringIO.new ''
          allow(File).to receive(:open).with(expected_path).and_yield(output)
          allow(File).to receive(:write)
          expect(FileUtils).to receive(:mkdir_p).with('./.abstract')

          state = YamlFile.new
          state.update 'key', {}
        end

        it 'should save hash as yaml to ./.abstract/state.yml' do
          backend_data = {
            'type' => 'gocd',
            'id' => 'a01b'
          }
          expected_path = './.abstract/state.yml'
          expected_content = "---\nbackend:\n  type: gocd\n  id: a01b\n"
          output = StringIO.new ''
          allow(File).to receive(:open).with(expected_path).and_yield(output)
          expect(File).to receive(:write).with(expected_path, expected_content)

          state = YamlFile.new
          state.update 'backend', backend_data
        end

        it 'should merge with existing state' do
          expected_path = './.abstract/state.yml'
          original_content = "---\nexistingkey:\n  type: random\n"
          output = StringIO.new original_content
          allow(File).to receive(:open).with(expected_path).and_yield(output)
          backend_data = {
            'type' => 'gocd',
            'id' => 'a01b'
          }
          backend_content = "backend:\n  type: gocd\n  id: a01b\n"
          expected_content = "#{original_content}#{backend_content}"
          expect(File).to receive(:write).with(expected_path, expected_content)

          state = YamlFile.new
          state.update 'backend', backend_data
        end
      end
    end
  end
end
