module HashToStruct
  def to_struct(recursive=false)
    keys, values = self.to_a.transpose
    return nil unless keys and values # in case of empty hash
    if recursive
      values = values.map { |v| (v.respond_to? :to_struct) ? v.to_struct(true) : v }
    end
    boolean_methods = []
    fields = keys.map do |field|
      if field.to_s.end_with? '?'
        boolean_method = field
        field = field.to_s.chomp('?')
        boolean_methods << [boolean_method.to_sym, field.to_sym]
      end
      field.to_sym
    end
    struct_class = Struct.new(*fields)
    boolean_methods.each do |boolean_method, field|
      struct_class.send(:define_method, boolean_method) do
        self.send(field)
      end
    end
    struct_class.new(*values)
  end
end

Hash.send(:include, HashToStruct)