module Rink
  module Version
    MAJOR = 1
    MINOR = 0
    PATCH = 2
    STRING = [MAJOR, MINOR, PATCH].join(".")
  end
  
  VERSION = Rink::Version::STRING
end
