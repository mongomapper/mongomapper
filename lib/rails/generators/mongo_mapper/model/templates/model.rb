<%- module_namespacing do -%>
<%- if parent_class_name.present? -%>
class <%= class_name %> < <%= parent_class_name.classify %>
<%- else -%>
class <%= class_name %>
  include MongoMapper::Document
<%- end -%>

<%- attributes.each do |attribute| -%>
  key :<%= attribute.name %>, <%= attribute.type.to_s.camelcase %>
<% end -%>
<%- if options[:timestamps] -%>
  timestamps!
<%- end -%>

end
<%- end -%>
