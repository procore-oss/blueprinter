class <%= class_name %>Blueprint < Blueprinter::Base
<% if identifier_symbol -%>
<%= indent -%>identifier :<%= identifier_symbol %>

<% end -%>
<% if fields.any? -%>
<%= indent -%>fields<%= formatted_fields %>

<% end -%>
<% associations.each do |a| -%>
<%= indent -%>association :<%= a -%><%= association_blueprint(a) %>

<% end -%>
end
