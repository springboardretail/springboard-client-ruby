class Class 
  def class_inheritable_reader(*syms)
    syms.each do |sym|
      class_eval <<-EOS
        def self.#{sym}
          read_inheritable_attr(:#{sym})
        end
      EOS
    end
  end

  def class_inheritable_writer(*syms)
    syms.each do |sym|
      class_eval <<-EOS
        def self.#{sym}=(obj)
          write_inheritable_attr(:#{sym},obj)
        end
      EOS
    end
  end
  
  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end
  
  # accessor for hash
  def inheritable_attrs
    @inheritable_attrs ||= {}   
  end

  # write variable into hash
  def write_inheritable_attr(key, value)
    inheritable_attrs[key] = value
  end

  # read variable from hash
  def read_inheritable_attr(key)
    inheritable_attrs[key]
  end
end