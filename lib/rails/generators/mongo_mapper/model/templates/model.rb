class <%= class_name %>
  include MongoMapper::Document

<% attributes.each do |attribute| -%>
  key :<%= attribute.name %>, <%= attribute.type_class %>
<% end -%>
<% if options[:timestamps] %>
  timestamps!
<% end -%>

end
