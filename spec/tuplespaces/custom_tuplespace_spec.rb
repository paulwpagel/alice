require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require "tuplespaces/custom_tuplespace"


describe Rinda::Tuplespaces::CustomTupleSpace do
  
  before(:each) do
    File.delete("test_bag.yml") if File.exists?("test_bag.yml")
  end
  
  after(:all) do
    File.delete("test_bag.yml") if File.exists?("test_bag.yml")
  end
  
  it "should use a regular tuplespace by default" do
    tuplespace = Rinda::Tuplespaces::CustomTupleSpace.new(:period => 123)
    tuplespace.bag.class.should eql(Rinda::TupleBag)
    tuplespace.period.should eql(123)
  end

end