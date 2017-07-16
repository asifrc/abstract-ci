require 'httparty'
require 'docker'

module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      def initialize
        @connected = false
        @container = nil
      end

      def create
        container = Docker::Container.create(
          'name' => 'abstract-gocd',
          'Image' => 'gocd/gocd-dev'
        )
        container.start
        @container = container
      end

      def connected?
        begin
          response = HTTParty.get("http://#{docker_host_ip}:8153",
                                  follow_redirects: false)
          @connected = true if response.headers['Location'].eql? '/go/home'
        rescue HTTParty::Error
          @connected = false
        end
        @connected
      end

      private

      def docker_host_ip
        `/sbin/ip route | awk '/default/ { print $3 }'`.strip
      end
    end
  end
end
