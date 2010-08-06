module Rink
  module InputMethod
    class IO < Rink::InputMethod::Base
      attr_accessor :input
      
      def initialize(input = $stdin)
        super()
        @input = input
        @line_num = 0
        @lines = []
      end
      
      def gets
        print @prompt
        line = @lines[@line_num += 1] = input.gets
        line += "\n" unless !line || line =~ /\n/
        print line if line
        line
      end
      
      def eof?
        input.eof?
      end
      
      def readable_after_eof?
        true
      end
      
      def [](line_number)
        @lines[line_number]
      end
    end
  end
end
