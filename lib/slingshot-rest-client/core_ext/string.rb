if !String.method_defined? :underscore
  module StringUnderscore
    def underscore
      return downcase if match(/\A[A-Z]+\z/)
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z])([A-Z])/, '\1_\2').
      downcase
    end
  end

  String.send(:include, StringUnderscore)
end