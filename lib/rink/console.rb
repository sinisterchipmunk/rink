module Rink
  class Console
    extend Rink::Delegation
    attr_reader :line_processor
    attr_writer :namespace, :silenced
    attr_reader :input, :output
    delegate :silenced?, :print, :write, :puts, :to => :output, :allow_nil => true
    
    def initialize(options = {})
      options = default_options.merge(options)
      apply_options(options)
      run(options)
    end
    
    def namespace
      @namespace ||= Object.new
    end

    def banner
      self.class.banner
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
      @_options = options
      @input  = setup_input_method(options[:input] || @input)
      @output = setup_output_method(options[:output] || @output)
      @output.silenced = options.key?(:silent) ? options[:silent] : !@output || @output.silenced?
      @namespace = options[:namespace] unless options[:namespace].nil?
      @line_processor = options.delete(:processor) || options.delete(:line_processor) || @line_processor
      
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

      # Default options are:
      #  :output => STDOUT,
      #  :input  => STDIN,
      #  :banner => true,
      #  :silent => false,
      #  :processor => Rink::LineProcessor::PureRuby.new(self)
      def default_options
        {
          :output => STDOUT,
          :input  => STDIN,
          :banner => true,
          :silent => false,
          :processor => Rink::LineProcessor::PureRuby.new(self)
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
    # printed to @output.
    def process_command(cmd)
      result = eval(cmd, namespace.send(:binding), self.class.name)
      "  => #{result.inspect}"
    end

    # Sends the command to #process_command and prints the result to @output.
    #
    # If an error occurs, the error and a backtrace are printed instead.
    def handle_input(cmd)
      puts process_command(cmd)
    rescue
      print $!.class.name, ": ", $!.message, "\n"
      print "\t", $!.backtrace.join("\n\t"), "\n"
    end
    

  private    
    include Rink::IOMethods

    def enter_input_loop
      while inln = @input.gets
        inln.strip!
        handle_input(inln) unless inln.length == 0
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
