require './spec/spec_helper'
require './lib/abstract/backend/gocd'

module Abstract
  module Backend
    describe GoCD do
      before(:all) do
        @docker_json = JSON.parse(
          File.read('./spec/fixtures/gocd_docker_json.json')
        )
        ip = @docker_json['NetworkSettings']['Gateway']
        port = @docker_json['NetworkSettings']['Ports']['8153/tcp']
               .first['HostPort']
        @server_url = "http://#{ip}:#{port}"
      end

      describe '#create' do
        before(:each) do
          @backend = GoCD.new
        end
        it 'should not be connected before create' do
          stub_request(:any, @server_url)
            .to_raise(HTTParty::Error)

          expect(@backend.connected?).to be false
        end

        it 'should attempt to create and start container' do
          @backend = GoCD.new
          container_id = '30c479f9525711427a8548557'
          stub_request(:any, @server_url)
            .to_raise(HTTParty::Error)

          stub_request(:post, %r{http://unix/.*/containers/create.*})
            .with(
              body: '{"Image":"gocd/gocd-dev","ExposedPorts":{"8153/tcp":{}},' \
                    '"HostConfig":{"PortBindings":{"8153/tcp":[{}]}}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(
              status: 201,
              body: "{\"Id\":\"#{container_id}\",\"Warnings\":null}",
              headers: { 'Content-Type' => 'application/json' }
            )

          starter_url = %r{http://unix/.*/containers/#{container_id}/start}
          starter_stub = stub_request(:post, starter_url)
                         .to_return(
                           status: 204,
                           body: ''
                         )
          json_url = %r{http://unix/.*/containers/#{container_id}/json}
          stub_request(:get, json_url)
            .to_return(
              status: 200,
              body: JSON.generate(@docker_json)
            )

          @backend.create

          expect(starter_stub).to have_been_requested
        end

        it 'should be connected after create' do
          @backend = GoCD.new
          container_id = '30c479f9525711427a8548557'
          stub_request(:any, @server_url)
            .to_raise(HTTParty::Error)

          stub_request(:post, %r{http://unix/.*/containers/create.*})
            .with(
              body: '{"Image":"gocd/gocd-dev","ExposedPorts":{"8153/tcp":{}},' \
                    '"HostConfig":{"PortBindings":{"8153/tcp":[{}]}}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(
              status: 201,
              body: "{\"Id\":\"#{container_id}\",\"Warnings\":null}",
              headers: { 'Content-Type' => 'application/json' }
            )

          starter_url = %r{http://unix/.*/containers/#{container_id}/start}
          stub_request(:post, starter_url)
            .to_return(
              status: 204,
              body: ''
            )

          json_url = %r{http://unix/.*/containers/#{container_id}/json}
          stub_request(:get, json_url)
            .to_return(
              status: 200,
              body: JSON.generate(@docker_json)
            )

          stub_request(:get, @server_url)
            .to_return(status: 301, body: '', headers: {
                         Location: '/go/home'
                       })
          stub_request(:any, "#{@server_url}/go/home")

          @backend.create

          expect(@backend.connected?).to be true
        end
      end

      describe '#server_url' do
        it 'should be nil by default' do
          backend = GoCD.new
          expect(backend.server_url.nil?).to be true
        end
        it 'should return an assigned value' do
          backend = GoCD.new
          backend.server_url = 'testvalue'
          expect(backend.server_url).to eq 'testvalue'
        end
      end

      describe '#connected?' do
        before(:each) do
          @backend = GoCD.new
          puts @server_url
          @root_stub = stub_request(:get, @server_url)
                       .to_return(status: 301, body: '', headers: {
                                    Location: '/go/home'
                                  })
          stub_request(:any, "#{@server_url}/go/home")
        end

        it 'should be connected if redirected to /go/home' do
          @backend.server_url = @server_url
          expect(@backend.connected?).to be true
        end

        it 'should attempt to connect to the go server' do
          @backend.server_url = @server_url
          @backend.connected?

          expect(@root_stub).to have_been_requested
        end

        it 'should not show as connected when go server does not respond' do
          stub_request(:any, @server_url)
            .to_raise(HTTParty::Error)

          expect(@backend.connected?).to be false
        end

        it 'should not be connected if root is not redirected to go home' do
          stub_request(:any, @server_url)
            .to_return(status: 200, body: '', headers: {})

          expect(@backend.connected?).to be false
        end
      end
    end
  end
end
