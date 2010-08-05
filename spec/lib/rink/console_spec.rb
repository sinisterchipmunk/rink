require 'spec_helper'

describe Rink::Console do
  class ExampleObject
    def inspect
      "#<example>"
    end
  end

  def console(*input)
    input = input.flatten.join("\n")
    subject.run(input, :output => @output, :silent => false)
  end

  before(:each) { @input = ""; @output = "" }
  subject { Rink::Console.new(:input => "", :silent => true) }
  
  it "should be able to exit" do
    # yeah, it was an oversight. Catching all Exceptions resulted in catching SystemExit, so the app couldn't be
    # stopped. Whoops.
    proc { console("exit") }.should raise_error(SystemExit)
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
    console("ExampleObject.new")
    @output.should =~ /  => #<example>$/
  end

  it "should not raise exceptions" do
    proc { console("test") }.should_not raise_error
  end

  it "should print exceptions" do
    console("test")
    @output.should =~ /ArgumentError: /
  end

  it "should ignore blank lines" do
    console("\n")
    prompt = Regexp::escape(subject.send(:prompt))
    @output.should =~ /^#{prompt}[\n\r]+#{prompt}$/
  end

  it "should allow setting namespace" do
    subject.namespace = ExampleObject.new
    console("inspect")
    @output.should =~ /  => "#<example>"$/
  end
end
