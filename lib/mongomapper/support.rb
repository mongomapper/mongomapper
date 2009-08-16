class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|instance_eval|proxy_|^object_id$)/ }
end unless defined?(BasicObject)

class Boolean
  def self.mm_typecast(value)
    ['true', 't', '1'].include?(value.to_s.downcase)
  end
end
