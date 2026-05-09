# Custom Extractor

Blueprinter V2 handles extraction from Hashes (symbol and string keys) and objects (`public_send`). If there's anything else you need to support, here's how:

```ruby
class FooExtractorExtension < Blueprinter::Extension
  def around_field_value(ctx)
    return yield ctx unless ctx.object.is_a? Foo
    
    extract(ctx.object, ctx.field.source)
  end
  
  def around_object_value(ctx)
    return yield ctx unless ctx.object.is_a? Foo
    
    extract(ctx.object, ctx.field.source)
  end
  
  def around_collection_value(ctx)
    return yield ctx unless ctx.object.is_a? Foo
    
    extract(ctx.object, ctx.field.source)
  end

  private

  def extract(object, attr)
    # extract attr from Foo object
  end
end
```
