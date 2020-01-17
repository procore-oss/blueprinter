Blueprinter.configure do |config|
  #  The default generator is JSON. You may replace it with OJ or Yajl as well.
  config.generator = <%= generator_gem -%>
<% if options["method"] -%>

  config.method = :<%= options["method"] -%>

<% else %>  #  Sometimes you may want to call a different method on the generator class, eg for Yajl
  #  config.method = :encode # default is generate
  #  see https://github.com/procore/blueprinter#yajl-ruby for details
<% end -%>

  #  a field or association that evaluates to nil is serialized as nil. To override this globally set a value:
<% if options["field_default"] -%>  config.field_default = <%= empty_string(options["field_default"]) ? "\"\"" : "\"#{options["field_default"]}\""  -%><%="\n" %><% else %>  #  config.field_default = "N\A"
<% end -%>
<% if options["association_default"] -%>  config.association_default = <%= options["association_default"] -%><%="\n" %><% else %>  #  config.association_default = {}
<% end -%>

  #  By default the response sorts the keys by name. They can also be sorted in the order of definition.
<% if options["sort_fields_by"] -%>
  config.sort_fields_by = :<%= options["sort_fields_by"] -%><%="\n" %><% else %>  #  config.sort_fields_by = :definition
<% end -%>

  #  If a global datetime_format is set (either as a string format or a Proc), this option will be invoked and used to format all fields that respond to strftime.
  #  config.datetime_format = ->(datetime) { datetime.nil? ? datetime : datetime.strftime("%s").to_i }
end
