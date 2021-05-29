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
    # Most of this is unnessersary for us. We really only need the plural-forms and
    # and language header. But just in case we'll tokenize them anyways
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
  # This is to allow for faster scanning.
  private KEYWORDS = {
    "msgctxt" => POTokens::MSGCTXT,
    "msgid" => POTokens::MSGID,
    "msgid_plural" => POTokens::MSGID_PLURAL,
    "msgstr" => POTokens::MSGSTR
  }

  # Hash mapping of string representation of headers to their enum counterpart.
  # This is to allow for faster scanning them
  private Headers = {
    "Project-Id-Version" => POTokens::PROJECT_ID_VERSION,
    "Report-Msgid-Bugs-To" => POTokens::REPORT_MSGID_BUGS_TO,
    "POT-Creation-Date" => POTokens::POT_CREATION_DATE,
    "PO-Revision-Date" => POTokens::PO_REVISION_DATE,
    "Last-Translator" => POTokens::LAST_TRANSLATOR,
    "Language-Team" => POTokens::LANGUAGE_TEAM,
    "Language" => POTokens::LANGUAGE,
    "Content-Type" => POTokens::CONTENT_TYPE,
    "Content-Transfer-Encoding" => POTokens::CONTENT_TRANSFER_ENCODING,
    "Plural-Forms" => POTokens::PLURAL_FORMS,
  }

  # Object representing a token from the grammar of gettext po files
  private struct Token < Base::Token
    def initialize(@token_type : POTokens, @literal : String?, @line : Int32)
    end
  end
end
