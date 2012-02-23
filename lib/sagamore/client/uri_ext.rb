module Sagamore
  class Client
    module URIExt
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        uri.join subpath.to_s.gsub(/^\//, '')
      end

      def merge_query_values!(values)
        self.query_values = (self.query_values || {}).merge(values)
      end
    end
  end
end

class Addressable::URI
  include Sagamore::Client::URIExt
end
