require "../base.cr"
require "./**"

module Gettext
  extend self

  # Enum of current supported Tokens for Gettext (po)
  private enum GettextTokens
    STRING
    PREV_MSGID
    MSGCTXT
    MSGID
    MSGID_PLURAL
    MSGSTR
    MSGSTR_PLURAL_ID
  end

  # Hash mapping string representation of keywords to their Enum type counterpart.
  # This is to allow for faster parsing.
  private KEYWORDS = {
    "msgctxt" => GettextTokens::MSGCTXT,
    "msgid" => GettextTokens::MSGID,
    "msgid_plural" => GettextTokens::MSGID_PLURAL,
    "msgstr" => GettextTokens::MSGSTR
  }

  # Object representing a token from the grammar of gettext po files
  private struct Token < Base::Token
    def initialize(@token_type : GettextTokens, @literal : String?, @line : Int32)
    end
  end
end
