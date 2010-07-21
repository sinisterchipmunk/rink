module Rink
  class Console
    attr_reader :input, :output
    attr_writer :namespace, :silenced
    
    def initialize(options = {})
      options = default_options.merge(options)
      apply_options(options)
      run(options.delete(:input), options)
    end

    def silenced?
      @silenced
    end

    def namespace
      @namespace ||= Object.new
    end

    def banner
      self.class.banner
    end

    def default_options
      self.class.default_options
    end

    def init_stream(stream_or_string)
      stream_or_string.kind_of?(String) ? StringIO.new(stream_or_string) : stream_or_string
    end

    def write(*args)
      return if silenced?
      args = args.flatten.join
      output.respond_to?(:print) ? output.print(args) : output.write(args)
    end

    alias print write

    def puts(*args)
      print args.join("\n")
      print "\n"
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
      temporary_options(options.merge(:input => input)) do
        puts banner if options.key?(:banner) ? options[:banner] : default_options[:banner]
        enter_input_loop
      end
    end

    def temporary_options(options)
      old_input, old_output, old_silence, old_namespace = @input, @output, @silenced, @namespace
      apply_options(options)
      yield
    ensure
      @input = old_input unless old_input.nil?
      @output = old_output unless old_output.nil?
      @silenced = old_silence unless old_silence.nil?
      @namespace = old_namespace unless old_namespace.nil?
    end

    def apply_options(options)
      @input  = init_stream(options[:input] || @input)
      @output = init_stream(options[:output] || @output)
      @silenced = options.key?(:silent) ? options[:silent] : @silenced
      @namespace = options[:namespace] unless options[:namespace].nil?
    end

    class << self
      def banner(msg = nil)
        if msg.nil?
          @banner ||= ">> Interactive Console <<"
        else
          @banner = msg
        end
      end

      def default_options
      {
        :input  => STDIN,
        :output => STDOUT,
        :banner => true,
        :silent => false
      }
      end
    end

  protected
    def prompt
      "#{self.class.name} > "
    end

    def handle_line(cmd)
      result = eval(cmd, namespace.send(:binding), self.class.name)
      puts "  => #{result.inspect}"
    rescue
      print $!.class.name, ": ", $!.message
      puts $!.backtrace
    end

  private
    def enter_input_loop
      print prompt
      while !input.closed? && inln = input.gets
        inln.strip!
        handle_line(inln) unless inln.length == 0
        print prompt
      end
    end
  end
end
