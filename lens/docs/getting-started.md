# Getting Started

## Why use Lens?
Lens was conceived due to various problems within crystal's internationalization ecosystem. As such, Lens aspires to overcome those issues. With lens:

* Support of **multiple** different formats
* **Constant** development of new features
* And soon, **actual full** number and time localization through CLDR

In short, Lens is packed full of features and designed for internationalizing.


## Installation
Lens is written in *pure* crystal and without any external dependencies besides Crystal itself. Thus, installing is as simple as appending Lens to your `shard.yml`!

```YAML
dependencies:
    lens:
    github: syeopite/lens
    version: ~> 0.1.0
```

After which, you just run `shards install` and Lens would be installed! 

## Usage

First let's import Lens into our program

```crystal
require  "lens"
```

Now we'll select a format!


!!! info hi inline end
    [See here for information regarding each format.](https://docs.weblate.org/en/latest/formats.html#translation-types-capabilities)

| Format | Backend|  Documentation |
|:--------:|:--------:|:----------------:|
| Gettext PO | `Gettext::POBackend` | [Here](/backends/gettext)
| Gettext MO | `Gettext::MOBackend` | [Here](/backends/gettext)
| Ruby YAML | `CrystalI18n::I18n` | [Here](/backends/ruby-yaml)


For this simple illustration lets use `Gettext::MOBackend`.

To get started we just simply initialize it with the locale directory:

```crystal
Gettext::MOBackend.new("locales")
```

And then call `#create`

```crystal
catalogue_hash =  Gettext::MOBackend.create()
catalogue_hash # => Hash(String, Catalogue) or LanguageCode | Filename => Catalogue

catalogue = catalogue_hash["en_US"]
```

!!! danger Note
    The API and behaviors for each backend **are different**! This is to **preserve** how the format typically handles stuff. For instance:

    ```crystal
    gettext_catalogue_hash = Gettext::MOBackend.new("locales").create 
    gettext_catalogue = gettext_catalogue["en_US"]

    yaml_catalogue = CrystalI18n::I18n.new("locales")

    # Gettext
    gettext_catalogue.gettext("A message")     # => "Translated message"
    gettext_catalogue.ngettext("I have %d apple", "I have %d apples", 50) # => "Translated I have %d apples"

    # Ruby YAML
    yaml_catalogue.translate("en", "translation") # => "Translated Message"
    catalogue.translate("en", "possessions.fruits.apples", 50) # => "I have 50 apples"
    ```

    What happens on a missing translation is also different:
    ```crystal
    yaml_catalogue.translate("en", "I don't exist") # => raises LensExceptions::MissingTranslation
    gettext_catalogue.gettext( "I don't exist")     # =>  "I don't exist"
    ```

    In the future there would be a `chain` backend, and an configuration option will be provided to migrate behavior differences. However, **the API for individual backends would always be different.** 

    Keep all of this in mind using Lens!

After which, we're able to freely translate!

```crystal
# Basic
catalogue.gettext("A message")     # => "Translated message"
# Plurals
catalogue.ngettext("I have %d apple", "I have %d apples", 1) # => "Translated I have %d apples"
# Context
catalogue.pgettext("CopyPasteMenu", "copy")          # => "Translated copy"
# Context w/ Plurals
catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 1) # => "Translated message with plural-form 0"
```


