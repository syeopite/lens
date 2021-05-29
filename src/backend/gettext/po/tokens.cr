require "../../base.cr"

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
    MSGSTR_PLURAL_ID

    # Headers
    PROJECT_ID_VERSION
    REPORT_MSGID_BUGS_TO
    POT_CREATION_DATE
    PO_REVISION_DATE
    LAST_TRANSLATOR
    LANGUAGE_TEAM
    LANGUAGE
    CONTENT_TYPE
    CONTENT_TRANSFER_ENCODING
    PLURAL_FORMS
  end

  # Hash mapping string representation of keywords to their Enum type counterpart.
  # This is to allow for faster parsing.
  private KEYWORDS = {
    "msgctxt" => POTokens::MSGCTXT,
    "msgid" => POTokens::MSGID,
    "msgid_plural" => POTokens::MSGID_PLURAL,
    "msgstr" => POTokens::MSGSTR
  }

  # Object representing a token from the grammar of gettext po files
  private struct Token < Base::Token
    def initialize(@token_type : POTokens, @literal : String?, @line : Int32)
    end
  end
end
