require 'fileutils'

module Abstract
  module State
    # Yaml Statefile
    #
    class YamlFile
      def load
        content = ''
        File.open('./.abstract/state.yml') do |file|
          content = file.read
        end
        YAML.safe_load(content) || {}
      rescue
        {}
      end

      def update(key, data)
        FileUtils.mkdir_p './.abstract'
        state_hash = load
        state_hash[key] = data
        content = YAML.dump state_hash
        File.write './.abstract/state.yml', content
      end
    end
  end
end
