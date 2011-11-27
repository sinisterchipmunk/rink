#require 'sc-ansi'

require File.expand_path(File.join(File.dirname(__FILE__), "core_ext/object"))
require File.expand_path(File.join(File.dirname(__FILE__), "rink/delegation"))
require File.expand_path(File.join(File.dirname(__FILE__), 'rink/namespace'))
require File.expand_path(File.join(File.dirname(__FILE__), "rink/lexer"))
require File.expand_path(File.join(File.dirname(__FILE__), 'rink/io_methods'))
require File.expand_path(File.join(File.dirname(__FILE__), "rink/line_processor/base"))
require File.expand_path(File.join(File.dirname(__FILE__), "rink/line_processor/pure_ruby"))
require File.expand_path(File.join(File.dirname(__FILE__), "rink/console"))
require File.expand_path(File.join(File.dirname(__FILE__), "rink/version"))

module Rink
  
end
