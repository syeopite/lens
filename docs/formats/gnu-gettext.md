# GNU Gettext
[Is GNU's implementation of the Gettext system ](https://www.gnu.org/software/gettext/) and also the most common translation format for libre-software. It has support for plurals, contexts, and contains a vast ecosystem of tools designed for it. 

The only caveat is that Gettext does **not** handle how fractional values can affect plural-forms. 

Gettext usually comes in two containers: 

  1. A human-readable `.po` file for translators 
  2. A binary `.mo` file for the program.

Lens provide support for both of these in the form of  `Gettext::POBackend` and `Gettext::MOBackend` respectively.

!!! Note
    Lens does not currently offer any method to export `.po` to `.mo`. So an external tool would have to be used. 

## Using Gettext

As with all backends, the first step is to initialize it with the locale directory. 

```crystal
gettext_backend = Gettext::MOBackend.new("locales")

```

Locale files are searched with the `**` glob, so feel free to nest in as many levels as you'd like.

!!! Tip inline end
    There are no API/behavior differences between the `po` and `mo` varieties. Anything that is shown to apply to one would also apply to the other.

Now you'll just need to call the `#create` method:

```crystal
catalogue_hash = gettext_backend.create()
```

Which returns a mapping of the language code, as defined via the `Language` header — or the file name when it isn't defined, to a Catalogue object. 

Now, we can begin translating!
```crystal
catalogue = catalogue_hash["en_US"]
```

The most basic syntax for translating strings is the `#gettext` method. If a translation is not found, then the original ID would be returned.

```crystal
catalogue.gettext("A message")     # => "Translated message"
catalogue.gettext("I don't exist") # => "I don't exist"
```

#### Pluralization

Plurals are handled through the `#ngettext` method. The given number is passed to the C expression from the `Plural-Forms` header, to compute which plural-form to use.

```crystal
catalogue.ngettext("I have %d apple", "I have %d apples", 0) # => "Translated I have %d apple"
catalogue.ngettext("I have %d apple", "I have %d apples", 1) # => "Translated I have %d apples"
```

#### Context

A translation can be constrained by a specific context, and can be accessed through the `#pgettext` method. This is useful to avoid ambiguities with commonly seen strings.

```crystal
catalogue.pgettext("CopyPasteMenu", "copy")          # => "Translated copy"
catalogue.pgettext("CopyPasteMenu", "I don't exist") # => "I don't exist"
```

#### Context w/ pluralization

A context-constrained translation can also have plurals, which are accessed through the `#npgettext` method
```crystal
catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 0) # => "Translated message with plural-form 1"
catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 1) # => "Translated message with plural-form 0"
```