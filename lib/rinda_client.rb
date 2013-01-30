require 'rinda/rinda'
module Rinda
  class RindaClient
    
    def self.tuplespace
      if not @tuplespace
        @server = DRb.start_service 
        dumb_guy = DRbObject.new(nil, "druby://#{CONFIG[:rinda_host]}:#{CONFIG[:rinda_port]}")
        @tuplespace = Rinda::TupleSpaceProxy.new(dumb_guy)
      end
      return @tuplespace
    end
    
    def self.close
      @tuplespace = nil
      @server.stop_service
    end
    
    def write(tuple, timeout = nil)
      with_tuplespace(timeout) do |tuplespace| 
        tuplespace.write(standardize(tuple), timeout) 
      end
    end
    
    def delayed_write(delay, tuple)
      tuple = standardize(tuple)
      with_tuplespace(nil) { |tuplespace| tuplespace.write(["delay", tuple], delay) }
    end
    
    def take(tuple, timeout = nil)
      catch_expiration do
        with_tuplespace(timeout) do |tuplespace|
          return tuplespace.take(standardize(tuple), timeout)
        end
      end
    end
    
    def read(tuple, timeout = nil)
      catch_expiration do
        with_tuplespace(timeout) do |tuplespace|
          return tuplespace.read(standardize(tuple), timeout)
        end
      end
    end
    
    def notify(event, tuple, timeout = nil)
      with_tuplespace(timeout) { |tuplespace| return tuplespace.notify(event, standardize(tuple), timeout)}
    end
    
    private ###############################################
    
    def with_tuplespace(timeout)
      expiration = timeout ? Time.now + timeout : nil
      begin
        tuplespace = self.class.tuplespace
        yield tuplespace
      rescue DRb::DRbServerNotFound
        self.class.close
        retry
      rescue DRb::DRbConnError
        sleep(0.1)
        raise Rinda::RequestExpiredError.new("Connection to Rinda server could not be established within desired duration (#{timeout} secs).") if expired?(expiration)
        retry
      ensure
      end
    end
    
    def expired?(expiration)
      return false if expiration.nil?
      return Time.now > expiration
    end
    
    def standardize(tuple)
      standard_tuple = Array.new(10)
      tuple.each_with_index { |value, index| standard_tuple[index] = value }
      return standard_tuple 
    end
    
    def catch_expiration
      begin
        yield
      rescue Rinda::RequestExpiredError
        return nil
      end
    end

  end
end