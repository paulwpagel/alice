require 'rinda_client'
require 'timeout' # Needed for errors - at least on some machines
require 'socket'

module Rinda
  class Rindlet
    
    NetworkErrors = [::Timeout::Error, ::Errno::EPIPE, ::SocketError, ::Errno::ECONNREFUSED]
    
    attr_accessor :rinda_client
    attr_accessor :pulse
    attr_accessor :number
    attr_reader :recoverable_exceptions
  
    def initialize(number, pulse = 5)
      @number = number
      @pulse = pulse
      @running = false
      @recoverable_exceptions = []
      @retry_delay = CONFIG[:rindlet_retry_delay] || 3600
    end
    
    def name
      @name = "#{self.class.name.split('::')[-1]}_#{number}" if not @name
      return @name
    end

    def start
      $logger.info "#{name} warming up..."
      @running = true
      do_standard_preparation
      prepare
      $logger.info "#{name} started."
      subscribe_to_monitor
      enter_loop
      finish_up
      $logger.info "#{name} stopped."
    end
  
    def running?
      return @running
    end

    def stop
      unsubscribe_to_monitor
      $logger.info "#{name} winding down..."
      @running = false
    end
    
    def recover_from(*exceptions_types)
      exceptions_types.each do |exception_type|
        @recoverable_exceptions << exception_type if not @recoverable_exceptions.include?(exception_type)
      end
    end
  
    protected #############################################
    
    def do_standard_preparation
      @rinda_client = RindaClient.new
    end

    def prepare
      # should be overridden by children
    end

    def run
      # should be overridden by children
    end
    
    def finish_up
      # should be overridden by children
    end
    
    def rinda_client
      @rinda_client = RindaClient.new if not @rinda_client
      return @rinda_client
    end
    
    def with_tuple(tuple, pulse = @pulse)
      tuple = rinda_client.take(tuple, pulse)
      if tuple
        begin
          yield(tuple)
        rescue Exception => e      
          if is_recoverable(e)
            recover(tuple, e)
          else
            raise
          end
        end
      end
    end

    def with_standard_tuple(context, task, pulse = @pulse)
      with_tuple([context, "request", task], pulse) do |tuple|
        begin
           yield(tuple)
        rescue Exception => e    
          if is_recoverable(e)
            recover(tuple, e)
          else
            standard_error_response(context, task, e, tuple)
          end
        end
      end
    end
    
    def standard_error_response(context, task, e, tuple, timeout=nil)
      @rinda_client.write([context, "response", task, "error", e.to_s, tuple], timeout)
      $logger.error e.to_s
      $logger.error e.backtrace.join("\n")
    end
        
    def subscribe_to_monitor
      @rinda_client.write(["monitor", "subscribe", name])
    end
    
    def unsubscribe_to_monitor
      @rinda_client.write(["monitor", "unsubscribe", name])
    end
    
    def check_for_ping
      with_tuple([name, "ping"], 0) do |tuple|
        @rinda_client.write(["monitor", "pong", name])
      end
    end
    
    def recover(tuple, exception)
      $logger.info "#{name} recovering tuple from exception: #{exception}"
      @rinda_client.delayed_write(@retry_delay, tuple)
    end
    
    private ###############################################
    
    def enter_loop
      begin
        while @running      
          check_for_ping
          run
        end
      rescue Exception => e
        $logger.error "Rindlet Error in #{name}: #{e}"
        $logger.error e.backtrace.join("\n")
      end
    end
    
    def is_recoverable(exception)
      return @recoverable_exceptions.include?(exception.class)
    end
    
  end
end

