module Rink
  class Namespace
    def initialize(ns = self.default_ns)
      replace(ns)
    end
    
    def binding
      @ns_binding
    end
    
    def ns
      @namespace
    end
    
    def replace(ns)
      return ns if ns.eql?(@namespace)
      @ns_binding = ns.instance_eval { binding }
              #ns.send(:binding) # this no worky in 1.9
      @namespace = ns
    end
    
    def evaluate(code, *filename_lineno)
      eval code, @ns_binding, *filename_lineno
    end
    
    def default_ns
      # We want namespace to be any object, and in order to do that, Rink will call namespace#binding.
      # But by default, the namespace should be TOPLEVEL_BINDING. If we set @namespace to this,
      # Rink will call TOPLEVEL_BINDING#binding, which is an error. So instead we'll create a singleton
      # object and override #binding on that object to return TOPLEVEL_BINDING. Effectively, that
      # singleton object becomes (more-or-less) a proxy into the toplevel object. (Is there a better way?)
      klass = Class.new(Object)
      klass.send(:define_method, :binding) { TOPLEVEL_BINDING }
      klass.new
    end
  end
end