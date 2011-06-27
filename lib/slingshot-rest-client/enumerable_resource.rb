##
# Experimental:
# If included, allows iterating over collection resources as though they were enumerables
#
# @example
# resource = SlingshotRestClient::Resource.new(
#   'http://services.slingshot.local/customers',
#   :user => 'admin',
#   :password => 'admin'
# )
#   
# resource.each do |customer|
#   puts customer.name
# end
#
module SlingshotRestClient
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
  end
end

class SlingshotRestClient::Resource
  include SlingshotRestClient::EnumerableResource
  include ::Enumerable
end