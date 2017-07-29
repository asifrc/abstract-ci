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
        @container_id = @docker_json['Id']
      end

      before(:each) do
        @mock_state = instance_double(Abstract::State::YamlFile)
        allow(@mock_state).to receive(:update)
        @backend = GoCD.new @mock_state

        stub_request(:post, %r{http://unix/.*/containers/create.*})
          .with(
            body: '{"Image":"gocd/gocd-dev","ExposedPorts":{"8153/tcp":{}},' \
                  '"HostConfig":{"PortBindings":{"8153/tcp":[{}]}}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 201,
            body: "{\"Id\":\"#{@container_id}\",\"Warnings\":null}",
            headers: { 'Content-Type' => 'application/json' }
          )

        starter_url = %r{http://unix/.*/containers/#{@container_id}/start}
        @starter_stub = stub_request(:post, starter_url)
                        .to_return(
                          status: 204,
                          body: ''
                        )
        json_url = %r{http://unix/.*/containers/#{@container_id}/json}
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
        @root_stub = stub_request(:get, @server_url)
                     .to_return(status: 301, body: '', headers: {
                                  Location: '/go/home'
                                })
        allow(@backend).to receive(:sleep)
      end

      describe '#create' do
        it 'should not be connected before create' do
          expect(@backend.connected?).to be false
        end

        it 'should attempt to create and start container' do
          @backend.create

          expect(@starter_stub).to have_been_requested.once
        end

        it 'should be connected after create' do
          @backend.create

          expect(@backend.connected?).to be true
        end

        it 'should create container only once when called twice' do
          @backend.create
          @backend.create

          expect(@starter_stub).to have_been_requested.once
        end

        it 'should save its state to a statefile' do
          expect(@mock_state).to receive(:update)
          @backend.create
        end
      end

      describe '#server_url' do
        it 'should be nil by default' do
          expect(@backend.server_url.nil?).to be true
        end

        it 'should return an assigned value' do
          @backend.server_url = 'testvalue'
          expect(@backend.server_url).to eq 'testvalue'
        end
      end

      describe '#connected?' do
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
            .to_raise(StandardError)

          @backend.server_url = @server_url
          expect(@backend.connected?).to be false
        end

        it 'should not be connected if root is not redirected to go home' do
          stub_request(:any, @server_url)
            .to_return(status: 200, body: '', headers: {})

          expect(@backend.connected?).to be false
        end
      end

      describe '#destroy' do
        it 'should attempt to kill the created container' do
          kill_url = %r{http://unix/.*/containers/#{@container_id}/kill}
          kill_stub = stub_request(:post, kill_url)
                      .to_return(
                        status: 204,
                        body: ''
                      )

          @backend.create
          @backend.destroy

          expect(kill_stub).to have_been_requested
        end

        it 'should return nil if there is no container to kill' do
          expect(@backend.destroy).to be nil
        end
      end

      describe '#valid_state?' do
        before(:each) do
          @valid_state = {
            'backend' => {
              'type' => 'GoCD',
              'driver' => 'docker',
              'id' => @container_id,
              'server_url' => @server_url
            }
          }
        end

        it 'should be valid if all required fields are present' do
          validity = @backend.valid_state? @valid_state

          expect(validity).to be true
        end
        it 'should be invalid if nil state' do
          validity = @backend.valid_state? nil
          expect(validity).to be false
        end

        it 'should be invalid if empty state' do
          validity = @backend.valid_state?({})
          expect(validity).to be false
        end

        it 'should be invalid when missing backend key' do
          invalid_state = {
            'something_else' => {}
          }
          validity = @backend.valid_state? invalid_state
          expect(validity).to be false
        end

        it 'should be invalid when missing any required keys' do
          %w[
            type
            driver
            id
            server_url
          ].each do |key|
            invalid_backend = @valid_state['backend'].dup
            invalid_backend.delete key
            invalid_state = {
              'backend' => invalid_backend
            }

            validity = @backend.valid_state? invalid_state

            expect(validity).to be false
          end
        end
      end

      describe '#wait_until_connected' do
        before(:each) do
          @server_stub = stub_request(:get, @server_url)
        end

        it 'should check connection once when zero retries' do
          @server_stub.to_raise(StandardError)
          @backend.retries = 0

          @backend.create
          @backend.wait_until_connected

          expect(@server_stub).to have_been_requested.once
        end

        it 'should check connection the number of retries specified plus one' do
          @server_stub.to_raise(StandardError)
          @backend.retries = 5

          @backend.create
          @backend.wait_until_connected

          expect(@server_stub).to have_been_requested.times 6
        end

        it 'should stop checking the connection once connected' do
          @server_stub
            .to_raise(StandardError)
            .to_raise(StandardError)
            .to_raise(StandardError)
            .then.to_return(status: 301, body: '', headers: {
                              Location: '/go/home'
                            })
          @backend.retries = 5

          @backend.create
          @backend.wait_until_connected

          expect(@server_stub).to have_been_requested.times 4
        end
      end
    end
  end
end
