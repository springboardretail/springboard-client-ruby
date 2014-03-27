require 'hashie'

module Springboard
  class Client
    ##
    # An indifferent Hash to represent parsed response bodies.
    #
    # @see http://rdoc.info/github/intridea/hashie/Hashie/Mash See the Hashie::Mash docs for usage details
    class Body < ::Hashie::Mash
    end
  end
end
