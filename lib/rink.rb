require File.expand_path(File.join(File.dirname(__FILE__), "core_ext/object"))

module Rink
  autoload :Delegation, "rink/delegation"
  autoload :Namespace, "rink/namespace"
  autoload :Lexer, "rink/lexer"
  autoload :IOMethods, "rink/io_methods"
  autoload :LineProcessor, "rink/line_processor"
  autoload :Console, "rink/console"
  autoload :Version, "rink/version"
end
