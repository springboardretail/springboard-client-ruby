##
# Experimental:
# If included, allows iterating over collection resources as though they were enumerables
#
# @example
# resource = Sagamore::RestClient::Resource.new(
#   'http://sagamore.local:8001/customers',
#   :user => 'admin',
#   :password => 'admin'
# )
#   
# resource.each do |customer|
#   puts customer.name
# end
#
module Sagamore::RestClient
  module EnumerableResource
    def each_page
      total_pages = nil
      page = 1
      while total_pages.nil? or page <= total_pages
        page_resource = query_string :page => page
        data = page_resource.get
        yield data
        total_pages ||= data[:pages]
        page += 1
      end
    end

    def each
      each_page do |page|
        page[:results].each do |result|
          yield result
        end
      end
    end

    ##
    # Optimized count method that fetches a small single page to determine the total without
    # iterating over all the pages.
    def count
      query_string(:page => 1, :per_page => 1).get.total
    end
  end
end

class Sagamore::RestClient::Resource
  include ::Enumerable
  include Sagamore::RestClient::EnumerableResource
end