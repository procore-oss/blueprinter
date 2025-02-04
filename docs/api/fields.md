# Fields

Extensions, reflection, and other APIs allow access to structs that describe fields.

> **type**\
> *Symbol* `:field | :object | :collection`\
> The type of field.

> **name**\
> *Symbol*\
> Name of the field as it will appear in the JSON or Hash output.

> **from**\
> *Symbol*\
> Name of the field in the source object (usually the same as `name`).

> **from_str**\
> *String*\
> Same as `from`, but as a frozen string.

> **value_proc**\
> *nil | Proc*\
> The block passed to the field definition (if given). Expects a [Field Context](./context-objects.md#field-context) argument and returns the field value.

> **options**\
> *Hash*\
> A frozen Hash of any additional options passed to the field.

> **blueprint** (object and collection only)\
> *Class*\
> The blueprint to use for serializaing the object or collection.
