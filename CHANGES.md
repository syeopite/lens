# Changelog


## Next
##### ETA: 2021-09-25

A preview of what's coming in the next version of Lens! 

Please note that this preview-list only contains what's currently implemented in master. [See the milestone for all the planned features.](https://github.com/syeopite/lens/milestone/1)

### CLDR (new)
- Add methods to compute number properties (float-aware) for better plural-form handling
- Add CLDR data for en
- Add ability to format numbers through patterns. See [#3](https://github.com/syeopite/lens/issues/3)

### Gettext
- **(performance)** Optimize parsing of Gettext (PO) and C plural-form expressions
- Fix merging of Gettext files with the same name. See [`ccd9d7d4`](https://github.com/syeopite/lens/commit/ccd9d7d40e847b1c6b3f2370267d336e18bdd6c3)

### RubyI18n
- **(BREAKING)** Rename CrystalI18n to RubyI18n
- **(BREAKING)** Rename CrystalI18n::I18n to RubyI18n::Yaml 
- **(BREAKING)** Get locale information from top-level key instead of file name. 
  - This means that translations should now be in this format:
  ```yaml
  # locales/test.yml
  en:
    message1: "translation"
    message2: "translation"

  # locales/other.yml
  fr:
    message1: "translation in french"
    message2: "translation in french"
  ```
- Add support for specifying a scope for fetching translations 
- Add ability to localize:
    - Numbers
    - Dates
    - Sizes
    - Currency 
    - Percentages

  Default data is provided for the en locale. Expect this to increase in the next version!
- Fix Moldovan's `few` plural-form.
- (**performance**) Improve translation look-up speeds by ~2x. 
- Add support for YAML files with `.yaml` extension.
  

### General
- Propagate the special error reporting of Gettext PO's *lexer* to all other lexers. Example:
  ```
    An error occurred when scanning 'Plural-Forms' at Line 1:
    nplurals=3; plural=($n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);
                        ^
    Unexpected character: '$' at column 21
  ```

- **(BREAKING)** Removal of stdlib overloads of #dig with Array. 
- **(BREAKING)** Remove ability to access backend through enum abstraction. (It didn't even work in the first place...)
- Overhaul parsing infrastructure to inherit from a base one 
- Fix typos

### Other
- Creation of reference documentation through mkdocs
- Add versioning to API docs
- Overhaul README

---
## v0.1.0 (2021-07-30)

Initial release