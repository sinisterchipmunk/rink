module Rink
  module OutputMethod
    class Base
      attr_writer :silenced
      
      def output
        raise NotImplementedError, "output"
      end
      
      def initialize(silenced = false)
        @silenced = silenced
      end
      
      def write(*args)
        print(*args)
      end
      
      def puts(*args)
        print args.join("\n"), "\n"
      end
      
      def print(*args)
        raise NotImplementedError, "print" unless silenced?
      end
      
      def silenced?
        @silenced
      end
    end
  end
end