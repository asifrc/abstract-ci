require 'httparty'

module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      def initialize
        @connected = false
      end

      def create
        begin
          HTTParty.get('http://localhost:8153')
          @connected = true
        rescue HTTParty::Error
          @connected = false
        end
        @connected
      end

      def connected?
        @connected
      end
    end
  end
end
