module Sagamore
  class Client
    module URIExt
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        uri.join subpath.to_s.gsub(/^\//, '')
      end

      def merge_query_values!(values)
        self.sagamore_query_values = (self.query_values || {}).merge(normalize_query_hash(values))
      end

      def sagamore_query_values=(values)
        retval = self.query_values = normalize_query_hash(values)
        # Hack to strip digits from Addressable::URI's subscript notation
        self.query = self.query.gsub(/\[\d+\]=/, '[]=')
        retval
      end

      private

      def normalize_query_hash(hash)
        hash.inject({}) do |copy, (k, v)|
          copy[k.to_s] = case v
            when Hash then stringify_hash_keys(hash)
            when true, false then v.to_s
            else v end
          copy
        end
      end
    end
  end
end

class Addressable::URI
  include Sagamore::Client::URIExt
end
