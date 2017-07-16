require './spec/spec_helper'
require './lib/abstract/backend/gocd'

module Abstract
  module Backend
    describe GoCD do
      describe 'Create' do
        before(:each) do
          @backend = GoCD.new
          @root_stub = stub_request(:any, 'http://localhost:8153/')
                       .to_return(status: 301, body: '', headers: {
                                    Location: '/go/home'
                                  })
          stub_request(:any, 'http://localhost:8153/go/home')
        end

        it 'should not be connected before create' do
          expect(@backend.connected?).to be false
        end

        it 'should be connected after create if redirect to /go/home' do
          @backend.create

          expect(@backend.connected?).to be true
        end

        it 'should attempt to connect to the go server' do
          @backend.create

          expect(@root_stub).to have_been_requested
        end

        it 'should not show as connected when go server does not respond' do
          stub_request(:any, 'http://localhost:8153/')
            .to_raise(HTTParty::Error)

          @backend.create

          expect(@backend.connected?).to be false
        end

        it 'should not be connected if root is not redirected to go home' do
          stub_request(:any, 'http://localhost:8153/')
            .to_return(status: 200, body: '', headers: {})

          @backend.create

          expect(@backend.connected?).to be false
        end
      end
    end
  end
end
