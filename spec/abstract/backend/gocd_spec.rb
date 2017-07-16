require './spec/spec_helper'
require './lib/abstract/backend/gocd'

module Abstract
  module Backend
    describe GoCD do
      describe '#create' do
        it 'should not be connected before create' do
          backend = GoCD.new
          stub_request(:any, 'http://localhost:8153/')
            .to_raise(HTTParty::Error)

          expect(backend.connected?).to be false
        end
      end

      describe '#connected?' do
        before(:each) do
          @backend = GoCD.new
          @root_stub = stub_request(:get, 'http://localhost:8153/')
                       .to_return(status: 301, body: '', headers: {
                                    Location: '/go/home'
                                  })
          stub_request(:any, 'http://localhost:8153/go/home')
        end

        it 'should be connected if redirected to /go/home' do
          expect(@backend.connected?).to be true
        end

        it 'should attempt to connect to the go server' do
          @backend.connected?

          expect(@root_stub).to have_been_requested
        end

        it 'should not show as connected when go server does not respond' do
          stub_request(:any, 'http://localhost:8153/')
            .to_raise(HTTParty::Error)

          expect(@backend.connected?).to be false
        end

        it 'should not be connected if root is not redirected to go home' do
          stub_request(:any, 'http://localhost:8153/')
            .to_return(status: 200, body: '', headers: {})

          expect(@backend.connected?).to be false
        end
      end
    end
  end
end
