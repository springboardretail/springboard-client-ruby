##
# This is an exception class that includes a special factory method, []
#
# @example Raising a REST error
#   raise DynamicError.new("Something went wrong", :bad_error, :details => [:what, :ev, :er])
#
# @example Using the factory method in a rescue clause
#   begin
#     raise DynamicError.new("Bad error", :validation_error, :things => [:one, :two, :three])
#   rescue DynamicError[:bad_error] => e
#     puts "#{e.message} affetcing #{e.error_data[:things].size} things"
#   rescue DynamicError
#     puts "Some other kind of rest error..."
#   end
#
# # Output: Bad error affecting 3 things
class DynamicError < StandardError

  class_inheritable_accessor :error_type

  attr_accessor :error_type
  attr_accessor :error_data

  ##
  # @param [String] message Optional error message
  # @param [Symbol] error_type Optional error type value used for matching in rescue clauses
  # @param [Hash] error_data Optional error_data
  #
  # @return [DynamicError]
  def initialize(message=nil, error_type=nil, error_data={})
    self.error_type = error_type
    self.error_data = error_data
    super(message)
  end

  ##
  # Returns the subclass for the error_type specified, or creates a new subclass using the factory
  # method
  #
  #  @param [Symbol] error_type error_type value for the subclass
  #
  # @return [Class] the previously, or newly, dynamically created subclass
  def self.[](error_type)
    self.const_get(error_type.to_s.classify)
  rescue NameError
    create_error_class(error_type)
  end

  ##
  # Factory method for creating subclasses of this class with
  # the error_type class attribute set to the given value
  #
  # @param [Symbol] error_type error_type value for the subclass
  #
  # @return [Class] the dynamically created subclass constant
  #
  # @example Creating a new error class
  # >> new_error_class = SlingshotRestClient::RestError.create_error_class(:new_error)
  # => SlingshotRestClient::RestError::NewError
  # >> new_error_class.error_type
  # => :new_error
  # >> new_error_class.name
  # => "SlingshotRestClient::RestError::NewError"
  #
  def self.create_error_class(error_type)
    klass = self.const_set(error_type.to_s.classify, Class.new(self))
    klass.error_type = error_type
    klass
  end

  ##
  # Overridden case equality operator to allow matching by error_type in rescue clauses
  #
  # @param [Object] obj Object to which self is compared
  #
  # @return [Boolean]
  def self.===(obj)
    if obj.kind_of?(DynamicError) and obj.error_type and self.error_type
      obj.error_type == self.error_type
    else
      super
    end
  end

  def is_a?(klass)
    return true if klass === self
    super
  end
end