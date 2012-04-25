module Sagamore
  class Client
    ##
    # Extensions to the Addressable::URI class.
    module URIExt
      ##
      # Returns a new URI with the given subpath appended to it. Ensures a single
      # forward slash between the URI's path and the given subpath.
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        uri.join subpath.to_s.gsub(/^\//, '')
      end

      ##
      # Merges the given hash of query string parameters and values with the URI's
      # existing query string parameters (if any).
      def merge_query_values!(values)
        self.sagamore_query_values = (self.query_values || {}).merge(normalize_query_hash(values))
      end

      private

      def sagamore_query_values=(values)
        retval = self.query_values = normalize_query_hash(values)
        # Hack to strip digits from Addressable::URI's subscript notation
        self.query = self.query.gsub(/\[\d+\]=/, '[]=')
        retval
      end

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

##
# We include Sagamore::Client::URIExt into Addressable::URI because its design
# doesn't support subclassing.
#
# @see http://addressable.rubyforge.org/api/Addressable/URI.html Addressable::URI docs
class Addressable::URI
  include Sagamore::Client::URIExt
end
