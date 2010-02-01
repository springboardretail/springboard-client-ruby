module StructToHash
  def to_hash(recursive=false)
    self.members.inject({}) do |hash, key|
      value = self[key]
      if recursive
        value = (value.is_a? Struct) ? value.to_hash(true) : value
      end
      hash[key.to_sym] = value
      hash
    end
  end
end

Struct.send(:include, StructToHash)