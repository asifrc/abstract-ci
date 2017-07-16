require './spec/spec_helper'
require './lib/abstract/backend/gocd'

module Abstract
  module Backend
    describe GoCD do
      before(:all) do
        @docker_host_ip = `/sbin/ip route | awk '/default/ { print $3 }'`.strip
        @server_url = "http://#{@docker_host_ip}:8153/"
      end

      describe '#create' do
        it 'should not be connected before create' do
          backend = GoCD.new
          stub_request(:any, @server_url)
            .to_raise(HTTParty::Error)

          expect(backend.connected?).to be false
        end

        it 'should attempt to create and start container' do
          backend = GoCD.new
          container_id = '30c479f9525711427a8548557'
          stub_request(:any, @server_url)
            .to_raise(HTTParty::Error)

          stub_request(:post, %r{http://unix/.*/containers/create.*})
            .with(body: '{"Image":"gocd/gocd-dev"}',
                  headers: { 'Content-Type' => 'application/json' })
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

          backend.create

          expect(starter_stub).to have_been_requested
        end
      end

      describe '#connected?' do
        before(:each) do
          @backend = GoCD.new
          @root_stub = stub_request(:get, @server_url)
                       .to_return(status: 301, body: '', headers: {
                                    Location: '/go/home'
                                  })
          stub_request(:any, "#{@server_url}go/home")
        end

        it 'should be connected if redirected to /go/home' do
          expect(@backend.connected?).to be true
        end

        it 'should attempt to connect to the go server' do
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
