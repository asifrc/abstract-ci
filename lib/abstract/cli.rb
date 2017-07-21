require 'thor'

require 'abstract/backend/gocd'

module Abstract
  # CLI using Thor
  #
  class CLI < Thor
    desc 'create', 'Create a new CI server'
    def create
      backend = Backend::GoCD.new
      backend.create
      backend.wait_until_connected
    end
  end
end
