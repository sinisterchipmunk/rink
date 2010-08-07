require 'spec_helper'

describe Rink::Namespace do
  class ExampleObject
    def initialize
      @i = 5
    end
  end
  
  subject { Rink::Namespace.new }
  
  it "should use the top ns by default" do
    subject.binding.should == TOPLEVEL_BINDING
  end
  
  context "with a different ns" do
    subject { Rink::Namespace.new(ExampleObject.new) }
    
    it "should not use the toplevel binding" do
      subject.binding.should_not == TOPLEVEL_BINDING
    end
    
    it "should evaluate code" do
      subject.evaluate("@i").should == 5
    end
  end
  
  it "should be replaceable" do
    subject.evaluate("@i").should_not == 5

    subject.replace(ExampleObject.new)
    subject.evaluate("@i").should == 5
  end
end