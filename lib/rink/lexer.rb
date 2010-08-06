require 'irb/ruby-lex'

module Rink
  class Lexer < ::RubyLex
    extend Rink::Delegation
    attr_accessor :output
    delegate :print, :puts, :write, :p, :to => :output
    
    def initialize(output = nil)
      @output = output
      super()
    end
    
    # RubyLex prompts unconditionally once the prompt is first set (not very reset-friendly), so we need to fix that.
    def set_prompt(p = nil, &block)
      if p.nil? && !block_given?
        @prompt = nil # this will go back to NOT prompting
      else
        super
      end
    end
    # overriding this method because we don't want to prompt
#      def each_top_level_statement
#    initialize_input
#    catch(:TERM_INPUT) do
#      loop do
#	begin
#	  @continue = false
#	  prompt
#	  unless l = lex
#	    throw :TERM_INPUT if @line == ''
#	  else
#	    #p l
#	    @line.concat l
#	    if @ltype or @continue or @indent > 0
#	      next
#	    end
#	  end
#	  if @line != "\n"
#	    yield @line, @exp_line_no
#	  end
#	  break unless l
#	  @line = ''
#	  @exp_line_no = @line_no
#
#	  @indent = 0
#	  @indent_stack = []
#	  prompt
#	rescue TerminateLineInput
#	  initialize_input
#	  prompt
#	  get_readed
#	end
#      end
#    end
#  end
  end
end