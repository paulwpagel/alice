require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "rindlet"

describe Rinda::Rindlet do
  
  class TestRindlet < Rinda::Rindlet
    def initialize(number, pulse = 5)
      super(number, pulse)
    end
    
    def run
      with_standard_tuple("test_context", "test") do |tuple|
        do_nothing
      end
    end
    
    def do_nothing
    end
    
    def do_standard_preparation
    end
    
    def enter_loop
      check_for_ping
      run
    end
  end
  
  before(:each) do
    @rindlet = TestRindlet.new(1)
    @rindlet.pulse = 0
    @rinda_client = MockRindaClient.new
    @rindlet.rinda_client = @rinda_client
  end
  
  it "should handle ping requests" do
    @rinda_client.takes << [[@rindlet.name, "ping"], [@rindlet.name, "ping"]]
    
    @rindlet.start
    
    @rinda_client.writes[1].should eql(["monitor", "pong",  @rindlet.name])    
  end
  
  it "should register with the monitor service on start up" do
    @rindlet.start
    @rinda_client.writes[0].should eql(["monitor", "subscribe", "TestRindlet_1"])
    
    @rindlet.send(:subscribe_to_monitor)
    @rinda_client.writes[1].should eql(["monitor", "subscribe", "TestRindlet_1"])
  end
  
  it "should only respond to monitor commands for the correct target/instance" do
    @rinda_client.takes << [[@rindlet.name, "ping"], [@rindlet.name, "ping"]]
    new_rindlet = TestRindlet.new(2)
    new_rindlet.rinda_client = @rinda_client
    
    new_rindlet.start
   @rinda_client.takes.size.should eql(1)
  end
  
  it "should unsubscribe when shutting down" do
    @rindlet.stop
    @rinda_client.writes[0].should eql(["monitor", "unsubscribe", "TestRindlet_1"])
  end
  
  it "should re-post the tuple when a recoverable exceptions" do
    @rindlet.recover_from(Timeout::Error)
    @rindlet.should_receive(:do_nothing).and_raise(Timeout::Error.new("blah"))  
    @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
    
    @rindlet.run
    
    @rinda_client.writes.length.should eql(0)
    @rinda_client.delayed_writes[0].should eql([3600, ["test_context", "request", "test"]])
  end
  
  it "should not re-post the tuple when the exception is not recoverable" do
    @rindlet.recover_from(Timeout::Error, NoMethodError)
    @rindlet.should_receive(:do_nothing).and_raise(SystemExit)  
    @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
    
    @rindlet.run
    
    @rinda_client.delayed_writes.length.should eql(0)
    @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", ["test_context", "request", "test"]])
  end
  
  it "should store standard network errors" do
    Rinda::Rindlet::NetworkErrors.should include(Timeout::Error)
    Rinda::Rindlet::NetworkErrors.should include(Errno::EPIPE)
    Rinda::Rindlet::NetworkErrors.should include(SocketError)
    Rinda::Rindlet::NetworkErrors.should include(Errno::ECONNREFUSED)
  end
  
  module Fiddle
    module Faddle
      class FfRindlet < Rinda::Rindlet
      end
    end
  end
  
  it "should not include the module in the Rindlet's name" do
    rindlet = Fiddle::Faddle::FfRindlet.new(1, 5)
    rindlet.name.should eql("FfRindlet_1")
  end

end
