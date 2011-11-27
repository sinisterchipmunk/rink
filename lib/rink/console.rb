module Rink
  class Console
    extend Rink::Delegation
    attr_reader :line_processor
    attr_writer :silenced
    attr_reader :input, :output
    delegate :silenced?, :print, :write, :puts, :to => :output, :allow_nil => true
    delegate :banner, :commands, :to => 'self.class'
    
    # One caveat: if you override #initialize, make sure to do as much setup as possible before calling super -- or,
    # call super with :defer => true -- because otherwise Rink will start the console before your init code executes.
    def initialize(options = {})
      options = default_options.merge(options)
      @namespace = Rink::Namespace.new
      apply_options(options)
      run(options) unless options[:defer]
    end
    
    def namespace=(ns)
      @namespace.replace(ns)
    end
    
    # The Ruby object within whose context the console will be run.
    # For example:
    #  class CustomNamespace
    #    def save_the_world
    #      'maybe later'
    #    end
    #  end
    #  
    #  Rink::Console.new(:namespace => CustomNamespace.new)
    #  # ...
    #  Rink::Console > save_the_world
    #  => "maybe later"
    #
    # This is most useful if you have an object with a lot of methods that you wish to treat
    # as console commands. Also, it segregates the user from the Rink::Console instance, preventing
    # them from making any changes to it.
    #
    # Note that you can set a console's namespace to itself if you _want_ the user to have access to it:
    #
    #  Rink::Console.new(:namespace => :self)
    #
    def namespace
      @namespace.ns
    end

    # Runs a series of commands in the context of this Console. Input can be either a string
    # or an input stream. Other options include:
    #
    #   :input     => a string or an input stream
    #   :output    => a string or an output stream.
    #   :banner    => boolean: whether to print a welcome banner.
    #   :silent    => boolean: whether to print any output at all.
    #   :namespace => any object (other than nil). Will be used as the default namespace.
    #
    # Note also that any value can be a proc. In this case, the proc will be called while
    # applying the options and the  return value of that proc will be used. This is useful
    # for lazy loading a value or for setting options based on some condition.
    #
    def run(input = {}, options = {})
      if input.kind_of?(Hash)
        options = options.merge(input)
      else
        options.merge! :input => input
      end
      
      temporary_options(options) do
        puts banner if options.key?(:banner) ? options[:banner] : default_options[:banner]
        enter_input_loop
      end
    end

    # runs a block of code with the specified options set, and then sets them back to their previous state.
    # Options that are nil or not specified will be inherited from the previous state; and options in the
    # previous state that are nil or not specified will not be reverted.
    def temporary_options(options)
      old_options = gather_options
      apply_options(options)
      yield
    ensure
      apply_options(old_options)
    end

    # Applies a new set of options. Options that are currently unset or nil will not be modified.
    def apply_options(options)
      return unless options
      
      options.each do |key, value|
        options[key] = value.call if value.kind_of?(Proc)
      end
      @_options ||= {}
      @_options.merge! options
      @input  = setup_input_method(options[:input] || @input)
      @output = setup_output_method(options[:output] || @output)
      @output.silenced = options.key?(:silent) ? options[:silent] : !@output || @output.silenced?
      @line_processor = options[:processor] || options[:line_processor] || @line_processor
      @allow_ruby = options.key?(:allow_ruby) ? options[:allow_ruby] : @allow_ruby

      if options[:namespace]
        ns = options[:namespace] == :self ? self : options[:namespace]
        @namespace.replace(ns)
      end
      
      if @input
        @input.output = @output
        @input.prompt = prompt
        if @input.respond_to?(:completion_proc)
          @input.completion_proc = proc { |line| autocomplete(line) }
        end
      end
    end
    
    # Returns the current set of options.
    def gather_options
      @_options
    end
    alias options gather_options

    class << self
      # Sets or returns the banner displayed when the console is started.
      def banner(msg = nil)
        if msg.nil?
          @banner ||= ">> Interactive Console <<"
        else
          @banner = msg
        end
      end
      
      # Sets or overrides a default option.
      #
      # Example:
      #
      #   class MyConsole < Rink::Console
      #     option :allow_ruby => false, :greeting => "Hi there!"
      #   end
      #
      def option(options)
        default_options.merge! options
      end
      
      # Sets or returns the prompt for this console.
      def prompt(msg = nil)
        if msg.nil?
          @prompt ||= "#{name} > "
        else
          @prompt = msg
        end
      end
      
      # Adds a custom command to the console. When the command is typed, a custom block of code
      # will fire. The command may contain spaces. Any words following the command will be sent
      # to the block as an array of arguments.
      def command(name, case_sensitive = false, &block)
        commands[name.to_s] = { :case_sensitive => case_sensitive, :block => block }
      end
      
      # Returns a hash containing all registered commands.
      def commands
        @commands ||= {}
      end
      
      # Default options are:
      #  :processor => Rink::LineProcessor::PureRuby.new(self),
      #  :output => STDOUT,
      #  :input  => STDIN,
      #  :banner => true,             # if false, Rink won't show a banner.
      #  :silent => false,            # if true, Rink won't produce output.
      #  :rescue_errors => true       # if false, Rink won't catch errors.
      #  :defer => false              # if true, Rink won't automatically wait for input.
      #  :allow_ruby => true          # if false, Rink won't execute unmatched commands as Ruby code.
      def default_options
        @default_options ||= {
          :output => STDOUT,
          :input  => STDIN,
          :banner => true,
          :silent => false,
          :processor => Rink::LineProcessor::PureRuby.new(self),
          :rescue_errors => true,
          :defer => false,
          :allow_ruby => true,
        }
      end
    end

    command(:exit) { |args| instance_variable_set("@exiting", true) }

  protected
    # The default set of options which will be used wherever an option from #apply_options is unset or nil.
    def default_options
      @default_options ||= self.class.default_options
    end

    # The prompt that is displayed next to the cursor.
    def prompt
      self.class.prompt
    end
    
    # Executes the given command, which is a String, and returns a String to be
    # printed to @output. If a command cannot be found, it is treated as Ruby code
    # and is executed within the context of @namespace.
    #
    # You can override this method to produce custom results, or you can use the
    # +:allow_ruby => false+ option in #run to prevent Ruby code from being executed.
    def process_line(line)
      args = line.split
      cmd = args.shift
      
      catch(:command_not_found) { return process_command(cmd, args) }

      # no matching commands, try to process it as ruby code
      if @allow_ruby
        result = process_ruby_code(line)
        puts "  => #{result.inspect}"
        return result
      end
      
      puts "I don't know the word \"#{cmd}.\""
    end
    
    def process_ruby_code(code)
      prepare_scanner_for(code)
      evaluate_scanner_statement
    end
    
    # Returns the instance of Rink::Lexer used to process Ruby code.
    def scanner
      return @scanner if @scanner
      @scanner = Rink::Lexer.new
      @scanner.exception_on_syntax_error = false
      @scanner
    end
    
    # Searches for a command matching cmd and returns the result of running its block.
    # If the command is not found, process_command throws :command_not_found.
    def process_command(cmd, args)
      commands.each do |command, options|
        if (options[:case_sensitive]  && cmd == command) ||
           (!options[:case_sensitive] && cmd.downcase == command.downcase)
          #return options[:block].call(args)
          return instance_exec(args, &options[:block])
        end
      end
      throw :command_not_found
    end

  private    
    include Rink::IOMethods
    
    def evaluate_scanner_statement
      _caller = @namespace.evaluate("caller")
      scanner.each_top_level_statement do |code, line_no|
        begin
          return @namespace.evaluate(code, self.class.name, line_no)
        rescue
          # clean out the backtrace so that it starts with the console line instead of program invocation.
          _caller.reverse.each { |line| $!.backtrace.pop if $!.backtrace.last == line }
          raise
        end
      end
    end
    
    def prepare_scanner_for(code)
      # the scanner prompt should be empty at first because we've already received the first line. Nothing to prompt for.
      scanner.set_prompt nil
      
      # redirect scanner output to @output so that prompts go where they belong
      scanner.output = @output
      
      # the meat: scanner will yield to set_input whenever it needs another line of code (including the first line).
      # the first yield must give the code we've already received; subsequent yields should get more data from @input.
      first = true
      scanner.set_input(@input) do
        line = if !first
          # For subsequent gets, we need a prompt.
          scanner.set_prompt prompt
          line = @input.gets
          scanner.set_prompt nil
          line
        else
          first = false
          code + "\n"
        end

        line
      end
    end

    def enter_input_loop
      @exiting = false
      while !@exiting && (cmd = @input.gets)
        cmd.strip!
        unless cmd.length == 0
          begin
            @last_value = process_line(cmd)
          rescue SystemExit, SignalException
            raise
          rescue Exception
            raise unless gather_options[:rescue_errors]
            print $!.class.name, ": ", $!.message, "\n"
            print "\t", $!.backtrace.join("\n\t"), "\n"
          end
        end
      end
      @last_value
    end
    
    # Runs the autocomplete method from the line processor, then reformats its result to be an array.
    def autocomplete(line)
      return [] unless @line_processor
      result = @line_processor.autocomplete(line, namespace)
      case result
        when String
          [result]
        when nil
          []
        when Array
          result
        else
          result.to_a
      end
    end
  end
end
