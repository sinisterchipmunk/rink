module Rink
  module InputMethod
    class File < Rink::InputMethod::Base
      def initialize(file)
        super
        @io = open(file)
      end

      def eof?
        @io.eof?
      end

      def gets
        print @prompt
        print(line = @lines[@line_num += 1] = @io.gets)
        line
      end
    end
  end
end