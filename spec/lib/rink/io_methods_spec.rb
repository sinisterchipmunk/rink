require 'spec_helper'

describe Rink::IOMethods do
  include Rink::IOMethods
  
  shared_examples_for "an input method" do
    it "should gets" do
      inln = @input.gets
      inln.should_not be_nil
      inln.length.should_not == 0
    end
  end
  
  context "input should be set up" do
    context "from a File" do
      before(:each) { setup_input_method(File.new(__FILE__, "r")).should be_kind_of(Rink::InputMethod::Base) }
      
      it_should_behave_like "an input method"
    end
    
    context "from a String" do
      before(:each) { setup_input_method("a string").should be_kind_of(Rink::InputMethod::Base) }
      
      it_should_behave_like "an input method"
    end
    
    context "from a StringIO" do
      before(:each) { setup_input_method(StringIO.new("a string")).should be_kind_of(Rink::InputMethod::Base) }
      
      it_should_behave_like "an input method"
    end
    
    context "from an InputMethod" do
      before(:each) { setup_input_method(setup_input_method("a string")).should be_kind_of(Rink::InputMethod::Base) }
      
      it_should_behave_like "an input method"
    end
  end
end
