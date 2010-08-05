module Rink
  module OutputMethod
    class IO < Rink::OutputMethod::Base
      attr_accessor :io
      
      def initialize(io)
        super()
        @io = io
      end
      
      def output
        @io
      end
      
      def print(*args)
        return if silenced?
        args = args.flatten.join
        @io.print(*args)
      end
    end
  end
end
