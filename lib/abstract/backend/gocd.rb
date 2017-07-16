require 'httparty'
require 'pry'

module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      def initialize
        @connected = false
      end

      def connected?
        begin
          response = HTTParty.get('http://localhost:8153',
                                  follow_redirects: false)
          @connected = true if response.headers['Location'].eql? '/go/home'
        rescue HTTParty::Error
          @connected = false
        end
        @connected
      end
    end
  end
end
