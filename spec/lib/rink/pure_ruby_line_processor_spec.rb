require 'spec_helper'

describe Rink::LineProcessor::PureRuby do
  subject { Rink::LineProcessor::PureRuby.new }
  
  it "should autocomplete" do
    subject.autocomplete('insp', Object.new).should == ["inspect"]
  end
  
  # probably don't need to test this directly since readline does it (and we know it works) ...
  # maybe test that autocomplete and whatnot are processed correctly, instead.
#  def console(*input)
#    input = input.flatten.join("\n")
#    subject.run(input, :output => @output, :silent => false)
#  end
#
#  before(:each) { @input = ""; @output = "" }
#  subject { Rink::Console.new(:input => "", :silent => true) }
#  
#  
#  it "should autocomplete 'help'" do
#    console("h\t")
#    @output.should =~ /> help/
#  end
#  
#  it "should not autocomplete 'help' from 'd'" do
#    console("d\t")
#    @output.should_not =~ /> dh?elp/
#  end
# 
#  it "should recall backward" do
#    console("1\n" + ANSI::move_up)
#    @output.should =~ / => 1$/
#  end
end
