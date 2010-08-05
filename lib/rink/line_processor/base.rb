module Rink
  module LineProcessor
    # The Line Processor takes partial lines and performs operations on them. This is usually triggered by some special
    # character or combination of characters, such as TAB, ARROW UP, ARROW DOWN, and so forth.
    #
    class Base
      attr_reader :source
      
      def initialize(source = nil)
        @source = source
      end
      
      # Autocomplete is usually triggered by a TAB character and generally involves looking at the beginning of a line
      # and finding the command the user is most likely trying to type. This saves typing for the user and creates a more
      # intuitive interface.
      #
      # This method returns either a single String or an array of Strings.
      def autocomplete(line, namespace)
        raise NotImplementedError, "autocomplete"
      end
    end
  end
end
