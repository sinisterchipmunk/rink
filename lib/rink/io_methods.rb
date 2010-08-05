require File.expand_path(File.join(File.dirname(__FILE__), "input_method/base"))
require File.expand_path(File.join(File.dirname(__FILE__), "input_method/readline"))
require File.expand_path(File.join(File.dirname(__FILE__), "input_method/io"))
require File.expand_path(File.join(File.dirname(__FILE__), "input_method/file"))
require File.expand_path(File.join(File.dirname(__FILE__), "output_method/base"))
require File.expand_path(File.join(File.dirname(__FILE__), "output_method/io"))

module Rink
  module IOMethods
    def setup_input_method(input)
      @input = case input
        when Rink::InputMethod::Base
          input
        when STDIN
          defined?(Rink::InputMethod::Readline) ? Rink::InputMethod::Readline.new : Rink::InputMethod::IO.new
        when File
          Rink::InputMethod::File.new(input)
        when String
          Rink::InputMethod::IO.new(StringIO.new(input))
        when ::IO, StringIO
          Rink::InputMethod::IO.new(input)
        #when nil
        #  nil
        else raise ArgumentError, "Unexpected input type: #{input.class}"
      end
    end
    
    def setup_output_method(output)
      @output = case output
        when Rink::OutputMethod::Base
          output
        when STDOUT, STDERR, ::IO, StringIO then
          Rink::OutputMethod::IO.new(output)
        when String
          Rink::OutputMethod::IO.new(StringIO.new(output))
        when nil then
          nil
        else
          raise ArgumentError, "Unexpected ouptut type: #{output.class}"
      end
    end
  end
end