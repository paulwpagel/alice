require 'rinda/tuplespace'

module Rinda
  module Tuplespaces
  
    class PersistentTupleBag < Rinda::TupleBag

      def initialize
        super()
        load
      end

      def size
        return @hash.size
      end

      def push(ary)
        result = super(ary)
        save
        return result
      end
  
      def delete(ary)
        result = super(ary)
        save
        return result
      end

      def delete_unless_alive
        result = super()
        save
        return result
      end

      protected ############################################# 

      def save
        # to be overridden
      end

      def load
        # to be overriden
      end

    end
  
  end
end