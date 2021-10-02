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
    version: ~> 0.2.0
```

After which, you just run `shards install` and Lens would be installed.

## Usage

First let's import Lens into our program

```crystal
require  "lens"
```

Now we'll select a format!


!!! info inline end
    [See here for information regarding each format.](https://docs.weblate.org/en/latest/formats.html#translation-types-capabilities)

| Format | Backend|  Documentation |
|:--------:|:--------:|:----------------:|
| GNU Gettext PO | `Gettext::POBackend` | [Here](/lens/formats/gnu-gettext)
| GNU Gettext MO | `Gettext::MOBackend` | [Here](/lens/formats/gnu-gettext)
| Ruby YAML | `CrystalI18n::I18n`[^1] | [Here](/lens/formats/ruby-yaml)


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


???+ danger note
    The API and behaviors for each backend **are different**! This is to **preserve** how the format typically handles stuff. 

    API differences:
    ```crystal
    
    # The Gettext backends requires a #create method. This returns an Hash of 
    # language code (or file name when the corresponding header isn't defined) 
    # to Catalogue objects
    gettext_catalogue_hash = Gettext::MOBackend.new("locales").create 
    gettext_catalogue = gettext_catalogue["en_US"]

    # The backend for ruby-yaml on the other hand is directly the catalogue.
    # No need for an additional #create. And naturally, it's also not a hash.
    yaml_catalogue = CrystalI18n::I18n.new("locales")

    # Gettext
    gettext_catalogue.gettext("A message")     # => "Translated message"
    gettext_catalogue.ngettext("I have %d apple", "I have %d apples", 50) # => "Translated I have %d apples"

    # Ruby YAML
    yaml_catalogue.translate("en", "translation") # => "Translated Message"
    catalogue.translate("en", "possessions.fruits.apples", 50) # => "I have 50 apples"
    ```

    Behavior differences:
    ```crystal
    yaml_catalogue.translate("en", "I don't exist") # => raises LensExceptions::MissingTranslation
    gettext_catalogue.gettext( "I don't exist")     # =>  "I don't exist"
    ```

    In the future there would be a `chain` backend, and a configuration option will be provided to migrate behavior differences. However, **the API for individual backends would always be different.** 

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


[^1]: Ruby YAML is the typical format seen in Crystal's internationalization ecosystem. However, each implementation often comes with minor adjustments tailored to their own APIs. Lens' version personally leans more towards the original RubyI18n version. 