require 'rinda/tuplespace'

module Rinda
  module Tuplespaces
    class CustomTupleSpace < Rinda::TupleSpace

      attr_reader :bag, :period

      def initialize(options)
        period = options[:period] || 60
        super(period)
        @bag = Rinda::TupleBag.new
      end

      def notify_event(event, tuple)
        $logger.info "#{event}: #{tuple}" if event != "close"
        super(event, tuple)
      end
    
      def to_s
        return @bag.to_s
      end
    
    end
  end
end