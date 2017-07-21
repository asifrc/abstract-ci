require 'httparty'
require 'docker'

module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      def initialize
        @connected = false
        @retries = 12
        @retry_interval = 5
      end

      def create
        return @server_url if @container
        @container = Docker::Container.create(container_options)
        @container.start
        protocol = 'http'
        ip = @container.json['NetworkSettings']['Gateway']
        port = @container.json['NetworkSettings']['Ports']['8153/tcp']
                         .first['HostPort']
        @server_url = "#{protocol}://#{ip}:#{port}"
      end

      def destroy
        @container.kill if @container
        @container = nil
      end

      def connected?
        if server_url
          begin
            response = HTTParty.get(@server_url,
                                    follow_redirects: false)
            @connected = true if response.headers['Location'].eql? '/go/home'
          rescue StandardError
            @connected = false
          end
        else
          @connected = false
        end
        @connected
      end

      def wait_until_connected
        total_retries = 0
        until connected? || total_retries == @retries
          total_retries += 1
          sleep @retry_interval
        end
        @connected
      end

      attr_accessor :server_url
      attr_accessor :retries
      attr_accessor :retry_interval

      private

      def container_options
        {
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
