begin
  require 'readline'
  
  module Rink
    module InputMethod
      class Readline < Rink::InputMethod::Base
        attr_accessor :completion_append_character, :completion_proc, :prompt
        
        def initialize(completion_proc = proc { |line| [] })
          super()
          
          @completion_append_character = nil
          @completion_proc = completion_proc
          @line_num = 0
          @lines = []
          @eof = false
        end
        
        def input
          $stdin
        end
        
        def gets
          # in case they were changed. Do we need this here?
          ::Readline.completion_append_character = completion_append_character 
          ::Readline.completion_proc = completion_proc
          
          if line = ::Readline.readline(@prompt, false)
            ::Readline::HISTORY.push(line) if !line.empty?
            @lines[@line_num += 1] = line + "\n"
          else
            @eof = true
            line
          end
        end
        
        def eof?
          @eof
        end
        
        def readable_after_eof?
          true
        end
        
        def [](line_num)
          @line[num]
        end
      end
    end
  end
rescue LoadError
  # Fail silently. Rink will fall back to an IO input type with STDIN.
end
