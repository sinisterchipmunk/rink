module Rink
  module InputMethod
    class Base
      STDIN_FILE_NAME = "(line)"
  
      def initialize(prompt = " > ", file = STDIN_FILE_NAME)
        @prompt = prompt
        @output = nil
        @filename = file
      end
  
      attr_reader :filename
      attr_accessor :prompt
      attr_accessor :output
      
      def encoding
        input.external_encoding
      end

      def input
        raise NotImplementedError, "input"
      end
      
      def print(*args)
        @output.print(*args) if @output
      end
      
      def puts(*args)
        @output.puts(*args) if @output
      end
      
      def write(*args)
        @output.write(*args) if @output
      end
  
      def gets
        raise NotImplementedError, "gets"
      end
  
      def readable_after_eof?
        false
      end
    end
  end
end
