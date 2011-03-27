class <%= class_name %>
  include MongoMapper::Document

<% attributes.each do |attribute| -%>
  key :<%= attribute.name %>, <%= attribute.to_s.camelcase %>
<% end -%>
<% if options[:timestamps] %>
  timestamps!
<% end -%>

end
