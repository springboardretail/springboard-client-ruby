module ArrayToStruct
  def to_struct(recursive=false)
    map { |v| (v.respond_to? :to_struct) ? v.to_struct(recursive) : v }
  end
end

Array.send(:include, ArrayToStruct)