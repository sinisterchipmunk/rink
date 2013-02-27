require 'spec_helper'

describe Rink::Console do
  class ::ExampleObject
    def inspect
      "#<example>"
    end
  end

  def console(*input)
    if input.last.kind_of?(Hash)
      options = input.pop
    else options = {}
    end
    input = input.flatten.join("\n")
    subject.run(input, {:output => @output, :silent => false, :rescue_errors => false}.merge(options))
  end

  before(:each) { @input = ""; @output = "" }
  subject { Rink::Console.new(:input => "", :silent => true) }
  
  it "should provide an option to not execute Ruby code" do
    console("x = 5", :allow_ruby => false)
    @output.should match(/I don't know the word \"x.\"/)
  end
  
  it "should not raise a NameError when invoking a dynamically-defined method" do
    console("def a; 5; end; a", :rescue_errors => false).should == 5
  end
  
  it "should retain local variables" do
    subject.run("x = 5\nx", :rescue_errors => false)
  end
  
  it "should be able to set itself as the namespace" do
    subject.run("self", :namespace => :self).should == subject
  end
  
  it "should return the last value executed" do
    console("1").should == 1
  end
  
  it "should not have a nil namespace!" do
    console("self").should_not be_nil
  end
  
  it "should be able to span ruby code over 2 lines" do
    proc { console("3.times do\nend", :rescue_errors => false) }.should_not raise_error
  end
  
  it "should not output multiple prompts" do
    console("3.times do |i|\nx = i\nend")
    @output.should == ">> Interactive Console <<\nRink::Console > 3.times do |i|\nRink::Console > x = i\nRink::Console > end\n  => 3\nRink::Console > "
  end
  
  it "should be able to span ruby code over 3 lines" do
    proc { console("3.times do |i|\nx = i\nend", :rescue_errors => false) }.should_not raise_error
    
    # this illustrates a totally different prob: losing scope over multiple inputs.
#    proc { console("x = 0\n3.times do |i|\nx += i\nend\nraise unless x == 3", :rescue_errors => false) }.
#            should_not raise_error
    
  end
  
  # May need a better way to test this.
  it "should be able to add hooks custom commands" do
    # Create a subclass of Rink::Console so we don't contaminate the environment
    klass = Class.new(Rink::Console)
    klass.command(:help) { |*args| puts 'how may I help you?' }
    k = klass.new(:input => "help", :output => @output, :rescue_errors => false)
    @output.should =~ /how may I help you\?/ 
  end
  
  it "should be able to exit" do
    # yeah, it was an oversight. Catching all Exceptions resulted in catching SystemExit, so the app couldn't be
    # stopped. Whoops.
    #proc { console("exit") }.should raise_error(SystemExit)
    
    # now an honest-to-goodness 'exit' command exists, so SystemExit doesn't get raised.
    # instead we'll just make sure that exit doesn't execute any further code.
    console("exit\n1").should_not == 1
  end

  it "should show a banner" do
    console
    @output.should =~ /\A>> Interactive Console <</
  end

  it "should have a prompt" do
    console
    prompt = Regexp::escape(subject.send(:prompt))
    @output.should =~ /^#{prompt}$/
  end

  it "should print return value, inspected" do
    console("ExampleObject.new", :rescue_errors => false)
    @output.should =~ /  => #<example>$/
  end

  it "should not raise exceptions" do
    proc { console("test", :rescue_errors => true) }.should_not raise_error
  end

  it "should print exceptions" do
    console("test", :rescue_errors => true)
    @output.should =~ /ArgumentError: /
  end

  it "should ignore blank lines" do
    console("\n")
    prompt = Regexp::escape(subject.send(:prompt))
    @output.should =~ /^#{prompt}[\n\r]+#{prompt}$/
  end

  it "should allow setting namespace" do
    obj = ExampleObject.new
    subject.namespace = obj
    subject.namespace.should == obj
    
    console("self").should == obj
  end

  it "should allow presetting namespace" do
    obj = ExampleObject.new
    console("self", :namespace => obj).should == obj
  end

  it "should allow lazily presetting namespace" do
    console("self", :namespace => proc { ExampleObject.new }).should be_kind_of(ExampleObject)
  end

  it "should be aware of commands defined in a superclass" do
    class TestClassA < Rink::Console
      command :foo do
      end
    end
    class TestClassB < TestClassA
    end
    TestClassB.commands['foo'].should_not be_nil
  end
end
