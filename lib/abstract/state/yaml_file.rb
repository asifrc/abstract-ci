require 'fileutils'

module Abstract
  module State
    # Yaml Statefile
    #
    class YamlFile
      def setup
        FileUtils.mkdir_p './.abstract'
      end

      def update(key, data)
        state_hash = {}
        state_hash[key] = data
        content = YAML.dump state_hash
        File.write './.abstract/state.yml', content
      end
    end
  end
end
