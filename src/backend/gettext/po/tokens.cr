module Gettext
  extend self

  # Enum of current supported Tokens for Gettext (po)
  private enum POTokens
    STRING
    PREV_MSGID
    MSGCTXT
    MSGID
    MSGID_PLURAL
    MSGSTR
    PLURAL_FORM

    # # Headers
    # # Most of this is unnecessary for us. We really only need the plural-forms and
    # # and language header. But just in case we'll tokenize them anyways
    # PROJECT_ID_VERSION
    # REPORT_MSGID_BUGS_TO
    # POT_CREATION_DATE
    # PO_REVISION_DATE
    # LAST_TRANSLATOR
    # LANGUAGE_TEAM
    # LANGUAGE
    # CONTENT_TYPE
    # CONTENT_TRANSFER_ENCODING
    # PLURAL_FORMS

    EOF
    DUMMY # Used as a dummy token in the parser
  end

  # Object representing a token from the grammar of gettext po files
  private struct Token
    property token_type, literal, line

    def initialize(@token_type : POTokens, @literal : String?, @line : Int32 | Int64)
    end
  end
end
