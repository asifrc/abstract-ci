require 'httparty'
require 'docker'

require 'abstract/state/yaml_file'

module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      attr_accessor :server_url
      attr_accessor :retries
      attr_accessor :retry_interval

      def initialize(state = nil)
        @retries = 12
        @retry_interval = 5
        @driver = 'docker'
        @state = state || Abstract::State::YamlFile.new
      end

      def create
        refresh_state
        return @container if @container
        @container = Docker::Container.create(container_options)
        @container.start
        protocol = 'http'
        ip = @container.json['NetworkSettings']['Gateway']
        port = @container.json['NetworkSettings']['Ports']['8153/tcp']
                         .first['HostPort']
        @server_url = "#{protocol}://#{ip}:#{port}"
        @state.update 'backend', 'type' => self.class.name,
                                 'driver' => @driver,
                                 'id' => @container.id,
                                 'server_url' => @server_url
        @container
      end

      def destroy
        refresh_state
        @container.kill if @container
        @container = nil
        @server_url = nil
        @state.update 'backend', nil
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

      def valid_state?(state)
        return false unless state.respond_to? :dig
        [
          ['backend'],
          %w[backend type],
          %w[backend driver],
          %w[backend id],
          %w[backend server_url]
        ].each do |required_path|
          return false if state.dig(*required_path).nil?
        end
        true
      end

      def wait_until_connected
        total_retries = 0
        until connected? || total_retries == @retries
          total_retries += 1
          sleep @retry_interval
        end
        @connected
      end

      private

      def refresh_state
        state = @state.load
        return unless valid_state? state
        @container = Docker::Container.get(state['backend']['id'])
        @server_url = state['backend']['server_url']
      end

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
