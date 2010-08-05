module Rink
  module LineProcessor
    # Performs autocompletion based on method names of objects used. This algorithm is identical to that of IRB.
    class PureRuby < Rink::LineProcessor::Base
      OPERATORS = ["%", "&", "*", "**", "+",  "-",  "/", "<", "<<", "<=", "<=>", "==", "===", "=~", ">", ">=", ">>",
                   "[]", "[]=", "^"
      ] unless defined?(OPERATORS)
      
      RESERVED_WORDS = [ "BEGIN", "END", "alias", "and", "begin", "break", "case", "class", "def", "defined", "do",
                         "else", "elsif", "end", "ensure", "false", "for", "if", "in", "module", "next", "nil", "not",
                         "or", "redo", "rescue", "retry", "return", "self", "super", "then", "true", "undef", "unless",
                         "until", "when", "while", "yield"
      ] unless defined?(RESERVED_WORDS)
      
      def autocomplete_for_regexp(receiver, message)
        candidates = Regexp.instance_methods(true)
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_array(receiver, message)
        candidates = Array.instance_methods(true)
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_proc_or_hash(receiver, message)
        candidates = Proc.instance_methods(true) | Hash.instance_methods(true)
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_symbol(sym)
        if Symbol.respond_to?(:all_symbols)
          candidates = Symbol.all_symbols.collect{|s| ":" + s.id2name}
          candidates.grep(/^#{sym}/)
        else
          []
        end
      end
      
      def autocomplete_for_absolute_constant_or_class_methods(receiver)
        candidates = Object.constants
        candidates.grep(/^#{receiver}/).collect{|e| "::" + e}
      end
      
      def autocomplete_for_constant_or_class_methods(receiver, message)
        begin
          candidates = eval("#{receiver}.constants | #{receiver}.methods", bind)
        rescue Exception
          candidates = []
        end
        candidates.grep(/^#{message}/).collect{|e| receiver + "::" + e}
      end
      
      def autocomplete_for_symbol_method(receiver, message)
        candidates = Symbol.instance_methods(true)
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_numeric(receiver, message)
        begin
          candidates = eval(receiver, bind).methods
        rescue Exception
          candidates = []
        end
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_hex_numeric(receiver, message)
        begin
          candidates = eval(receiver, bind).methods
        rescue Exception
          candidates = []
        end
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_global_variable(obj)
        global_variables.grep(Regexp.new(obj))
      end
      
      def autocomplete_for_variable(receiver, message)
        gv = eval("global_variables", bind)
        lv = eval("local_variables", bind)
        cv = eval("self.class.constants", bind)
        
        if (gv | lv | cv).include?(receiver)
          # foo.func and foo is local var.
          candidates = eval("#{receiver}.methods", bind)
        elsif /^[A-Z]/ =~ receiver and /\./ !~ receiver
          # Foo::Bar.func
          begin
            candidates = eval("#{receiver}.methods", bind)
          rescue Exception
            candidates = []
          end
        else
          # func1.func2
          candidates = []
          ObjectSpace.each_object(Module){|m|
            begin
              name = m.name
            rescue Exception
              name = ""
            end
            next if name != "IRB::Context" and 
              /^(IRB|SLex|RubyLex|RubyToken)/ =~ name
            candidates.concat m.instance_methods(false)
          }
          candidates.sort!
          candidates.uniq!
        end
        select_message(receiver, message, candidates)
      end
      
      def autocomplete_for_string(message)
        receiver = ""
        candidates = String.instance_methods(true)
        select_message(receiver, message, candidates)
      end
      
      def autocomplete(line, namespace)
        # Borrowed from irb/completion.rb
        case line
          when /^(\/[^\/]*\/)\.([^.]*)$/
            autocomplete_for_regexp($1, Regexp.quote($2))
            
          when /^([^\]]*\])\.([^.]*)$/
            autocomplete_for_array($1, Regexp.quote($2))

          when /^([^\}]*\})\.([^.]*)$/
            autocomplete_for_proc_or_hash($1, Regexp.quote($2))
	
          when /^(:[^:.]*)$/
            autocomplete_for_symbol($1)

          when /^::([A-Z][^:\.\(]*)$/
            autocomplete_for_absolute_constant_or_class_methods($1)

          when /^(((::)?[A-Z][^:.\(]*)+)::?([^:.]*)$/
            autocomplete_for_constant_or_class_methods($1, Regexp.quote($4))

          when /^(:[^:.]+)\.([^.]*)$/
            autocomplete_for_symbol_method($1, Regexp.quote($2))

          when /^(-?(0[dbo])?[0-9_]+(\.[0-9_]+)?([eE]-?[0-9]+)?)\.([^.]*)$/
            autocomplete_for_numeric($1, Regexp.quote($5))

          when /^(-?0x[0-9a-fA-F_]+)\.([^.]*)$/
            autocomplete_for_hex_numeric($1, Regexp.quote($2))
          
          when /^(\$[^.]*)$/
            autocomplete_for_global_variable(Regexp.quote($1))
            
    #      when /^(\$?(\.?[^.]+)+)\.([^.]*)$/
          when /^((\.?[^.]+)+)\.([^.]*)$/
            autocomplete_for_variable($1, Regexp.quote($3))

          when /^\.([^.]*)$/
            # unknown(maybe String)
            autocomplete_for_string(Regexp.quote($1))
          else
            candidates = eval("methods | private_methods | local_variables | self.class.constants", namespace.send(:binding))
            (candidates|RESERVED_WORDS).grep(/^#{Regexp.quote(line)}/)
        end
      end
      
      private
      def select_message(receiver, message, candidates)
        candidates.grep(/^#{message}/).collect do |e|
          case e
            when /^[a-zA-Z_]/
              receiver + "." + e
            when /^[0-9]/
            when *OPERATORS
              #receiver + " " + e
          end
        end
      end
    end
  end
end