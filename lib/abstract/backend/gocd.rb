module Abstract
  module Backend
    # GoCD Backend
    #
    class GoCD
      def initialize
        @connected = false
      end

      def create
        @connected = true
      end

      def connected?
        @connected
      end
    end
  end
end
