require 'spec_helper'

describe "the 'person' namespace example" do
  class Person
    attr_reader :first_name
    def initialize
      @first_name = "Colin"
    end
  end
  
  class MyConsole < Rink::Console
    option :namespace => Person.new
  end
  
  subject { MyConsole.new(:input => StringIO.new(""), :output => StringIO.new("")) }
  
  it "should autocomplete properly" do
    subject.send(:autocomplete, "firs").should == ['first_name']
  end
end
