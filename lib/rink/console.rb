module Rink
  class Console
    extend Rink::Delegation
    attr_reader :line_processor
    attr_writer :namespace, :silenced
    attr_reader :input, :output
    delegate :silenced?, :print, :write, :puts, :to => :output, :allow_nil => true
    delegate :banner, :commands, :to => 'self.class'
    
    def initialize(options = {})
      options = default_options.merge(options)
      apply_options(options)
      run(options)
    end
    
    def namespace
      @namespace ||= Object.new
    end

    # Runs a series of commands in the context of this Console. Input can be either a string
    # or an input stream. Other options include:
    #
    #   :output    => a string or an output stream.
    #   :banner    => boolean: whether to print a welcome banner.
    #   :silent    => boolean: whether to print any output at all.
    #   :namespace => any object (other than nil). Will be used as the default namespace.
    #
    def run(input, options = {})
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

    def temporary_options(options)
      old_options = gather_options
      apply_options(options)
      yield
    ensure
      apply_options(old_options)
    end

    def apply_options(options)
      return unless options
      @_options ||= {}
      @_options.merge! options
      @input  = setup_input_method(options[:input] || @input)
      @output = setup_output_method(options[:output] || @output)
      @output.silenced = options.key?(:silent) ? options[:silent] : !@output || @output.silenced?
      @namespace = options[:namespace] unless options[:namespace].nil?
      @line_processor = options[:processor] || options[:line_processor] || @line_processor
      
      if @input
        @input.output = @output
        @input.prompt = prompt
        if @input.respond_to?(:completion_proc)
          @input.completion_proc = proc { |line| autocomplete(line) }
        end
      end
    end
    
    def gather_options
      @_options
    end

    class << self
      # Sets or returns the banner displayed when the console is started.
      def banner(msg = nil)
        if msg.nil?
          @banner ||= ">> Interactive Console <<"
        else
          @banner = msg
        end
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
      #  :output => STDOUT,
      #  :input  => STDIN,
      #  :banner => true,
      #  :silent => false,
      #  :processor => Rink::LineProcessor::PureRuby.new(self),
      #  :rescue_errors => true
      def default_options
        {
          :output => STDOUT,
          :input  => STDIN,
          :banner => true,
          :silent => false,
          :processor => Rink::LineProcessor::PureRuby.new(self),
          :rescue_errors => true,
        }
      end
    end

  protected
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
    # You can override this method to produce custom results.
    def process_line(line)
      catch(:command_not_found) { return process_command(line) }
      
      # no matching commands, try to eval it as ruby code
      result = eval(line, namespace.send(:binding), self.class.name)
      "  => #{result.inspect}"
    end
    
    # Searches for a command matching cmd and returns the result of running its block.
    # If the command is not found, process_command throws :command_not_found.
    def process_command(cmd)
      commands.each do |command, options|
        #$stdout.puts options.inspect, command.inspect, cmd.inspect
        #$stdout.puts '--'
        if (options[:case_sensitive]  && cmd[/^#{Regexp::escape command}\s*(.*)/]) ||
           (!options[:case_sensitive] && cmd[/^#{Regexp::escape command}\s*(.*)/i])
          args = $~[1].split
          return options[:block].call(args)
        end
      end
      throw :command_not_found
    end

  private    
    include Rink::IOMethods

    def enter_input_loop
      puts
      while cmd = @input.gets
        cmd.strip!
        unless cmd.length == 0
          begin
            puts process_line(cmd)
          rescue SystemExit
            raise
          rescue Exception
            raise unless gather_options[:rescue_errors]
            print $!.class.name, ": ", $!.message, "\n"
            print "\t", $!.backtrace.join("\n\t"), "\n"
          end
          puts
        end
      end
    end
    
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
