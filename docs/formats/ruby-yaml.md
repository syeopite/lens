# Ruby YAML
Is the YAML format [used by ruby-i18n](https://github.com/ruby-i18n/i18n) and the format implemented by all of the internationalization libraries in Crystal prior to Lens. [See here for more information regarding the format.](https://guides.rubyonrails.org/i18n.html)

Ruby YAML has support for plurals, defined with CLDR data. This means that it *can* handle plural forms of both Integers and floating point numbers. However, this has **not** been added to Lens as of writing. Expect to see it in either `v0.2.0` or `v0.3.0`.



## Using Ruby YAML

The Ruby YAML backend is the `RubyI18n::Yaml`. To initialize, simply pass in the locale directory:

```crystal
catalogue = RubyI18n::Yaml.new("locales")
```

Now, we can begin translating!


The most basic syntax for translating is just the `#translate` method. Simply pass in the language code for that specific locale and the key for the specific translation.

```crystal
catalogue.translate("en", "translation") # => "Translated Message"
catalogue.translate("en", "I don't exist!") # raises LensExceptions::MissingTranslation
```

!!! Tip 
    If you'd like to use Ruby YAML monolingually, you can use the `#select` method to set a specific language for translations.

    ```crystal
    catalogue.select("en")
    catalogue.translate("translation") # => "Translated Message"
    ```

Nested keys can be accessed by separating routes with `.`

```crystal
catalogue.translate("en", "nested_key.forth.forth-third.forth-third-fifth.4344")
```

#### Pluralization

Messages requiring plurals are handled by passing in a number to the `#translate` method:

```crystal
catalogue.translate("en", "possessions.fruits.apples", 50) # => "I have 50 apples"
catalogue.translate("en", "possessions.fruits.apples", 1)  # => "I have 1 apple"
```

Plural-Rules follows CLDR (integers-only for now) and is pre-defined in lens for many languages. If your language isn't included in lens you many define (or even overwrite) a new plural-rule through the `CrystalI18n.define_rule` method

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