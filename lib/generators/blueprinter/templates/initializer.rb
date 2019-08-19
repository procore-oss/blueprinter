Blueprinter.configure do |config|
<% if options["field_default"] -%>  config.field_default = <%= empty_string(options["field_default"]) ? "\"\"" : "\"#{options["field_default"]}\""  -%><%="\n" %><% end -%>
<% if options["association_default"] -%>  config.association_default = <%= options["association_default"] -%><%="\n" %><% end -%>
<% if generator_gem -%>  config.generator = <%= generator_gem -%><%="\n" %><% end -%>
<% if options["method"] -%>  config.method = :<%= options["method"] -%><%="\n" %><% end -%>
<% if options["sort_fields_by"] -%>  config.sort_fields_by = :<%= options["sort_fields_by"] -%><%="\n" %><% end -%>
end
