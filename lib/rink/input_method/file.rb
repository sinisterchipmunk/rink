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
        line = @lines[@line_num += 1] = @io.gets
        line += "\n" unless !line || line =~ /\n/
        print(line)
        line
      end
    end
  end
end