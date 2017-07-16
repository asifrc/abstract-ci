require 'httparty'
require 'docker'

module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      def initialize
        @connected = false
        @server_url = nil
      end

      def create
        container = Docker::Container.create(container_options)
        container.start
        protocol = 'http'
        ip = container.json['NetworkSettings']['Gateway']
        port = container.json['NetworkSettings']['Ports']['8153/tcp']
                        .first['HostPort']
        @server_url = "#{protocol}://#{ip}:#{port}"
      end

      def connected?
        if server_url
          begin
            response = HTTParty.get(@server_url,
                                    follow_redirects: false)
            @connected = true if response.headers['Location'].eql? '/go/home'
          rescue HTTParty::Error
            @connected = false
          end
        else
          @connected = false
        end
        @connected
      end

      attr_accessor :server_url

      private

      def container_options
        {
          'name' => 'abstract-gocd',
          'Image' => 'gocd/gocd-dev',
          'ExposedPorts' => { '8153/tcp' => {} },
          'HostConfig' => {
            'PortBindings' => {
              '8153/tcp' => [{}]
            }
          }
        }
      end
    end
  end
end
