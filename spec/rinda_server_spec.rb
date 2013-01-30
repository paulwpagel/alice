require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "rinda_server"


RINDA_FILE = "/tmp/rinda_test.yml"

describe Rinda::RindaServer do

  before(:each) do
    CONFIG[:rinda_shutdown_wait] = 0
    @server = Rinda::RindaServer.new(9123, :period => 0.5, :tuplespace => :ram)
    @server.delay = Proc.new { Thread.pass }
    $logger.clear
  end
  
  it "should have all the components" do
    @server.port.should eql(9123)
    @server.tuplespace.should_not be(nil)
    @server.tuplespace.bag.should_not be(nil)
    # @server.tuplespace.bag.data_source.should eql(RINDA_FILE)
  end
  
  def start_server
    thread_exception = nil
    @server_thread = Thread.new do 
      begin
        @server.start 
      rescue Exception => e
        thread_exception = e
        puts e
      end
    end
    while(not @server.running? and not thread_exception)
      Thread.pass
    end
  end
  
  def stop_server
    @server.stop
    @server_thread.join(1) if @server_thread
  end
  
  it "should start and stop" do
    @server.running?.should eql(false)
    
    start_server
    @server.running?.should eql(true)
    
    stop_server
    @server.running?.should eql(false)
    @server_thread.alive?.should eql(false) if @server_thread
  end

  it "should start DRB and watcher thread on start up" do
    lambda { DRbObject.new(nil, 'druby://localhost:9123').respond_to?(:write) }.should raise_error
    
    start_server
    lambda { DRbObject.new(nil, 'druby://localhost:9123').respond_to?(:write) }.should_not raise_error
  
    stop_server
    lambda { DRbObject.new(nil, 'druby://localhost:9123').respond_to?(:write) }.should raise_error
  end
  
  it "should log writes" do
    start_server
    @server.tuplespace.write([1])
    sleep(0.1)
    
    stop_server
    $logger.infos.should include("write: [1]")
  end
  
  it "should log takes" do
    start_server
    @server.tuplespace.write([1])
    tuple = @server.tuplespace.take([nil])
    sleep(0.1)
    
    stop_server
    $logger.infos.should include("take: [1]")
  end
  
  it "should log deletes" do
    start_server
    @server.tuplespace.write([1], -1)
    sleep(0.1)
    
    stop_server
    $logger.infos.should include("delete: [1]")
  end
  
  it "should start and stop timer thread" do
    @server.timer_thread.should be(nil)
    
    start_server
    sleep(0.1)
    @server.timer_thread.alive?.should eql(true)
  
    stop_server
    @server.timer_thread.alive?.should eql(false)
  end
  
  it "should handle delayed tuples" do
    start_server
    @server.tuplespace.write(["delay", [1]], 0.5)
    sleep(1)
    stop_server
    
    $logger.infos.should include("write: [delay, [1]]")
    $logger.infos.should include("delete: [delay, [1]]")
    $logger.infos.should include("write: [1]")
  end

end
