require 'rinda/tuplespace'


module Rinda
  
  class NotifyTemplateEntry
    def each_so_far
      while !@queue.empty?
        it = pop
        yield(it)
      end
    end
  end
  
  class Template
    def to_s
      return "Template:#{value}"
    end
  end
  
end

class Array
  def to_s
    return "[#{self.collect { |v| v.nil? ? 'nil' : v.to_s[0..50] }.join(", ")}]"
  end
end
