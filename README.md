# Lens
[![GitHub release](https://img.shields.io/github/release/syeopite/lens.svg)](https://github.com/syeopite/lens/releases) [![Lens CI](https://github.com/syeopite/lens/actions/workflows/ci.yml/badge.svg)](https://github.com/syeopite/lens/actions/workflows/ci.yml) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://syeopite.github.io/lens/)

A multi-format internationalization (i18n) shard for Crystal.

Lens is designed to be fast, versatile and simple to use! Supports the likes of Gettext, Ruby YAML and more.


## Why use Lens?
Lens was conceived due to various problems within crystal's internationalization ecosystem. As such, Lens aspires to overcome those issues. With lens:

* Support of **multiple** different formats
* **Constant** development of new features
* And soon, **actual full** number and time localization through CLDR

In short, Lens is packed full of features and designed for internationalization.

**Note: Documentation below is for Master. [For the stable release version, please see v0.1.0.](https://syeopite.github.io/lens/getting-started)**


## Getting started 

Lens supports numerous different formats:

| Format | Backend|  Documentation |
|:--------:|:--------:|:----------------:|
| GNU Gettext PO | `Gettext::POBackend` | [Here](https://syeopite.github.io/lens/formats/gnu-gettext)
| GNU Gettext MO | `Gettext::MOBackend` | [Here](https://syeopite.github.io/lens/formats/gnu-gettext)
| Ruby YAML | `RubyI18n::Yaml` | [Here](https://syeopite.github.io/lens/formats/ruby-yaml)


To get started, simply initialize a backend: 
```crystal
backend = Gettext::MOBackend.new("locales")
```

And begin translating!
```crystal
catalogue = backend.create["en_US"]

# Basic
catalogue.gettext("A message")     # => "Translated message"
# Plurals
catalogue.ngettext("I have %d apple", "I have %d apples", 1) # => "Translated I have %d apples"
# Context
catalogue.pgettext("CopyPasteMenu", "copy")          # => "Translated copy"
# Context w/ Plurals
catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 1) # => "Translated message with plural-form 0"
```

Note that each backend has a slightly different API.

[See Getting Started for more information](https://syeopite.github.io/lens/getting-started)


## Installation
1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lens:
       github: syeopite/lens
       version: ~> v0.1.0
   ```

2. Run `shards install`

## Documentation
[Reference](https://syeopite.github.io/lens/)

[Library API](https://syeopite.github.io/lens/api/)


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
* [TechMagister/i18n.cr](https://github.com/TechMagister/i18n.cr)
* [crystal-i18n/i18n](https://github.com/crystal-i18n/i18n)
