module HeartlandRetail
  class Client
    ##
    # Mixin provides {Resource} with special methods for convenient interaction
    # with collection resources.
    module Collection
      include ::Enumerable

      ##
      # Iterates over all results from the collection and yields each one to
      # the block, fetching pages as needed.
      #
      # @raise [RequestFailed]
      def each(&block)
        call_client(:each, &block)
      end

      ##
      # Iterates over each page of results and yields the page to the block,
      # fetching as needed.
      #
      # @raise [RequestFailed]
      def each_page(&block)
        call_client(:each_page, &block)
      end

      ##
      # Performs a request and returns the number of resources in the collection.
      #
      # @raise [RequestFailed]
      #
      # @return [Integer] The subordinate resource count
      def count
        call_client(:count)
      end

      ##
      # Returns true if count is greater than zero, else false.
      #
      # @see #count
      #
      # @raise [RequestFailed]
      #
      # @return [Boolean]
      def empty?
        count <= 0
      end

      ##
      # Returns a new resource with the given filters added to the query string.
      #
      # @see https://github.com/springboard/springboard-retail/blob/master/api/doc/filtering.md Heartland Retail collection API filtering docs
      #
      # @param [String, Hash] new_filters Hash or JSON string of new filters
      #
      # @return [Resource]
      def filter(new_filters)
        new_filters = JSON.parse(new_filters) if new_filters.is_a?(String)
        if filters = query['_filter']
          filters = JSON.parse(filters)
          filters = [filters] unless filters.is_a?(Array)
          filters.push(new_filters)
        else
          filters = new_filters
        end
        query('_filter' => filters.to_json)
      end

      ##
      # Returns a new resource with the given sorts added to the query string.
      #
      # @example
      #   resource.sort('id,desc', 'name', 'custom@category,desc', :description)
      #
      # @param [#to_s] sorts One or more sort strings
      #
      # @return [Resource]
      def sort(*sorts)
        query('sort' => sorts)
      end

      ##
      # Returns a new resource with the given fields added to the query string as _only parameters.
      #
      # @example
      #    resource.only('id', :public_id)
      #
      # @param [#to_s] returns One or more fields
      #
      # @return [Resource]
      def only(*fields)
        query('_only' => fields)
      end

      ##
      # Performs a request to get the first result of the first page of the 
      # collection and returns it.
      #
      # @raise [RequestFailed]
      #
      # @return [Body] The first entry in the response :results array
      def first
        response = query(:per_page => 1, :page => 1).get!
        response[:results].first
      end

      ##
      # Performs repeated GET requests to the resource and yields results to
      # the given block as long as the response includes more results.
      #
      # @raise [RequestFailed]
      def while_results(&block)
        loop do
          results = get![:results]
          break if results.nil? || results.empty?
          results.each(&block)
        end
      end
    end
  end
end
