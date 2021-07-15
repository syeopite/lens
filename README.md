# lens

A multiformat internationalization (i18n) shard for Crystal.

There is no doubt that the crystal community lacks many essential features that most modern day languages have; one of which is internationalization. Lens is an attempt to fix that.

## Getting started 
Lens supports numerous different formats:
* GNU Gettext
    * You can use both .po and .mo
* Crystal-i18n
    * Stored under .yml
* More coming soon

To get started, you should select one that fits your needs the best. [See here for information regarding them.](https://docs.weblate.org/en/latest/formats.html#l)

``` crystal
  require "lens"

  backend = Lens.fetch_backend(Lens::Formats::GettextMO) # => Gettext::MOBackend
```

Each backend can then be initialized with the locale directory
```crystal
backend = backend.new("locales")
```

Each backend also supports nested directories and multiple files of the same language.

## GNU Gettext
The GNU project's implementation of Gettext
```crystal
backend = Gettext::MOBackend.new("locales")
catalogue_hash = backend.create() # => LanguageCode|| Filename => Catalogue 
catalogue = catalogue_hash["en_US"]
```

For detailed information regarding usage please refer to the actual API documentation. A brief overview of the functionality is present below.


#### Basic usage
Messages are fetched with the `gettext` method. If it doesn't exist then the given ID would be returned.
```crystal
catalogue.gettext("A message")     # => "Translated message"
catalogue.gettext("I don't exist") # => "I don't exist"
```

#### Pluralization
Pluralization is done through the `ngettext` method. The given number is parsed through the C expression from the Plural-Forms header to know which plural-form to use.

```crystal
catalogue.ngettext("I have %d apple", "I have %d apples", 0) # => "Translated I have %d apple"
catalogue.ngettext("I have %d apple", "I have %d apples", 1) # => "Translated I have %d apples"
```

#### Context
Key can be constrained by a specific context and is accessed through the pgettext method.
```crystal
catalogue.pgettext("CopyPasteMenu", "copy")          # => "Translated copy"
catalogue.pgettext("CopyPasteMenu", "I don't exist") # => "I don't exist"
```

#### Context with pluralization
Context-constrained messages can also have plural-forms and is accessed through the `npgettext` method
```crystal
catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 0) # => "Translated message with plural-form 1"
catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 1) # => "Translated message with plural-form 0"
```

## Crystal-i18n
Is a format based on ruby-yml similar to what many others in the crystal community has implemented.
```crystal
# The backend is the catalogue in the case of crystal-i18n
catalogue = CrystalI18n::I18n.new("locales")
```

Each file should be named like `language-code.yml`

For detailed information regarding usage please refer to the actual API documentation. A brief overview of the functionality is present below.

#### Basic usage
```crystal
catalogue.translate("en", "translation") # => "Translated Message"
```

Nested keys can be accessed by separating routes with `.`

```crystal
catalogue.translate("en", "nested_key.forth.forth-third.forth-third-fifth.4344")
```


#### Pluralization
```crystal
catalogue.translate("en", "possessions.fruits.apples", 50) # => "I have 50 apples"
catalogue.translate("en", "possessions.fruits.apples", 1)  # => "I have 1 apple"
```

Plural-rules follows CLDR and is pre-defined in lens for many languages. If your language isn't included in lens you many define (or even overwrite) a new plural-rule through the `CrystalI18n.define_rule` method

```crystal
  CrystalI18n.define_rule("ar", ->(n : Int32 | Int64 | Float64) {
  case
  when n == 0             then "zero"
  when n == 1             then "one"
  when n == 2             then "two"
  when 3..10 === n % 100  then "few"
  when 11..99 === n % 100 then "many"
  else                         "other"
  end
})
```


#### Interpolation
Interpolation is done through keyword arguments in the `#translate` method
```crystal
# message is 'Hello there, my name is %{name} and I'm a %{profession}`.
result = catalogue.translate("en", "introduction.messages", name: "Steve", profession: "programmer")
result # => "Hello there, my name is Steve and I'm a programmer"
```

#### Iteration
If the value at the given path (key) turns out to be an array then you can pass in the iter argument to select a specific value at the given index

```crystal
catalogue.translate("en", "items.foods", iter: 2) # => "Hamburger"
```

## API documentation
[Here](https://syeopite.github.io/lens/index.html)

## Installation
1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lens:
       github: syeopite/lens
   ```

2. Run `shards install`

## Contributing

1. Fork it (<https://github.com/syeopite/lens/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [syeopite](https://github.com/syeopite) - creator and maintainer

## Inspirations
* [omarroth/gettext.cr](https://github.com/omarroth/gettext.cr)
* [TechMagister/i18n.cr](https://github.com/TechMagister/i18n)
* [crystal-i18n/i18n](https://github.com/crystal-i18n/i18n)
