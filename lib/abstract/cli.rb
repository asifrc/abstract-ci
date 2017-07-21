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
    end
  end
end
