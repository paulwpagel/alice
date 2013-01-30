$: << File.dirname(__FILE__) + "/../lib"
require 'rspec'
require 'rubygems'
CONFIG = {} unless defined? CONFIG

class MockLogger
  attr_reader :infos
  
  def initialize
    @infos = []
  end
  
  def info(message)
    @infos << message
  end
  
  def error(message)
  end
  
  def fatal(message)
  end
  
  def clear
  end
  
end
$logger = MockLogger.new

class MockRindaClient
  
  attr_accessor :reads, :takes, :writes, :delayed_writes, :timeouts
  
  def initialize
    @reads = []
    @takes = []
    @writes = []
    @timeouts = []
    @delayed_writes = []
  end
  
  def read(tuple, timeout = nil)
    @reads.each_with_index do |pair, index| 
      if pair[0] == tuple
        return pair[1] 
      end
    end
    return nil
  end
  
  def take(tuple, timeout = nil)
    @takes.each_with_index do |pair, index|
      if pair[0] == tuple
        @takes.delete_at(index)
        return pair[1] 
      end
    end
    return nil
  end
  
  def write(tuple, timeout = nil)
    @writes << tuple
    @timeouts << timeout
  end
  
  def delayed_write(delay, tuple)
    @delayed_writes << [delay, tuple]
  end
  
  def self.close
  end
  
end