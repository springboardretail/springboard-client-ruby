module Sagamore
  class Client
    module URIExt
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        uri.join subpath.to_s.gsub(/^\//, '')
      end

      def merge_query_values!(values)
        self.sagamore_query_values = (self.query_values || {}).merge(stringify_hash_keys(values))
      end

      def sagamore_query_values=(values)
        retval = self.query_values = values
        # Hack to strip digits from Addressable::URI's subscript notation
        self.query = self.query.gsub(/\[\d+\]=/, '[]=')
        retval
      end

      private

      def stringify_hash_keys(hash)
        hash.inject({}) do |copy, (k, v)|
          copy[k.to_s] = (v.is_a? Hash) ? stringify_hash_keys(hash) : v
          copy
        end
      end
    end
  end
end

class Addressable::URI
  include Sagamore::Client::URIExt
end
