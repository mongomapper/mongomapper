<% module_namespacing do -%>
class <%= class_name %>
  include MongoMapper::Document

<% attributes.each do |attribute| -%>
  key :<%= attribute.name %>, <%= attribute.type.to_s.camelcase %>
<% end -%>
<% if options[:timestamps] %>
  timestamps!
<% end -%>

end
<% end -%>