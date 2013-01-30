require "patches"
require "thread"
require 'tuplespaces/custom_tuplespace'

module Rinda
    
  class RindaServer
    
    attr_accessor :delay
    attr_reader :port, :tuplespace, :timer_thread
    
    def initialize(port, options = {})
      @port = port
      @tuplespace = Tuplespaces::CustomTupleSpace.new(options)
      @running = false
      @delay = Proc.new { sleep(1) }
      @lock = Mutex.new
    end
    
    def running?
      return @running
    end
    
    def start
      raise "RindaServer is already running." if @running
      $logger.info "RindaServer starting up on port:#{@port} with tuplespace:#{@tuplespace}."
      create_notifiers
      @service = DRb.start_service("druby://:#{port}", @tuplespace)
      @running = true
      @timer_thread = Thread.new { run_timer }
      $logger.info "RindaServer running..."
    end
    
    def join
      @service.thread.join if @service.thread
    end
    
    def stop
      sleep(0)
      raise "RindaServer is not running." if not @running
      $logger.info "RindaServer on port:#{@port} shutting down."
      close_notifiers
      @running = false
      @timer_thread.join if @timer_thread
      @service.stop_service
      self.join
      $logger.info "RindaServer is down."
    end
    
    private #-----------------------
    
    def create_notifiers
      @timer_notifier = @tuplespace.notify('delete', ["delay", nil])
    end
    
    def close_notifiers
      @timer_notifier.notify("close")
    end
    
    def run_timer
      begin
        while(@running)
          @delay.call
          @timer_notifier.each_so_far do |event, tuple|
            @tuplespace.write tuple[1] if tuple
          end
        end
      rescue Exception => e
        $logger.error e
      end
    end
    
  end  
end