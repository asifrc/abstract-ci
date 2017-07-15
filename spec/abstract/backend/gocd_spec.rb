require './spec/spec_helper'
require './lib/abstract/backend/gocd'

module Abstract
  module Backend
    describe GoCD do
      describe 'Create' do
        it 'should not be connected before create' do
          backend = GoCD.new
          expect(backend.connected?).to be false
        end
        it 'should be connected after create' do
          backend = GoCD.new
          backend.create
          expect(backend.connected?).to be true
        end
      end
    end
  end
end
