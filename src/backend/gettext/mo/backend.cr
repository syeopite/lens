require "../gettext.cr"

module Gettext
  extend self

  # The backend for Gettext's MO files. This class contains methods to parse and interact with them.
  #
  # Similar to the Gettext module from Python, feel free to subclass and override the internal `#parse_` method
  # to create a backend for other .mo files. However, please consider opening a PR and adding it directly
  # to lens instead!
  struct MOBackend < Backend
    LE_MAGIC = 0x950412de
    BE_MAGIC = 0xde120495

    # Create a new MO backend instance that reads from the given locale directory path
    #
    # ```
    # Gettext::MOBackend.new("locales")
    # ```
    def initialize(@locale_directory_path : String)
    end

    # Parse gettext mo files into message catalogues.
    #
    # This is returned as a mapping of the language code to the catalogue
    # in which the language code is taken from the `Language` header. If
    # none can be found then the mo file name is used as a fallback.
    #
    # ```
    # backend = Gettext::MOBackend.new("locales")
    # backend.parse # => Hash(String, Catalogue)
    # ```
    define_public_parse_function("mo")

    # Internal parse method. Reads bytes from IO to produce messages from Gettext's mo
    private def parse_(file_name, io : IO) : Hash(String, Hash(Int8, String))
      messages = {} of String => Hash(Int8, String)
      # Taken from omarroth's gettext.cr's MO parsing https://github.com/omarroth/gettext.cr/blob/master/src/gettext.cr#L374-L461

      case version = io.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      when LE_MAGIC
        endianness = IO::ByteFormat::LittleEndian
      when BE_MAGIC
        endianness = IO::ByteFormat::BigEndian
      else
        raise "Invalid magic"
      end

      # Fetches version, number of strings, offset to raw strings, offset to translated strings
      version, msgcount, raw_offset, trans_offset = Array.new(4) { |i| io.read_bytes(UInt32, endianness) }
      if !{0, 1}.includes? version >> 16
        raise "Unsupported version"
      end

      msgcount.times do |i|
        io.seek(raw_offset + i * 8)
        mlen, moff = Array.new(2) { |i| io.read_bytes(UInt32, endianness) }
        io.seek(trans_offset + i * 8)
        tlen, toff = Array.new(2) { |i| io.read_bytes(UInt32, endianness) }

        # The reference implementation https://github.com/python/cpython/blob/3.7/Lib/gettext.py
        # checks that msg and tmsg are bounded within the buffer, which we skip here

        io.seek(moff)
        msg = Bytes.new(mlen)
        io.read_utf8(msg)

        io.seek(toff)
        tmsg = Bytes.new(tlen)
        io.read_utf8(tmsg)

        # Plural messages
        if msg.includes? 0x00
          msgid, plural_msgid = String.new(msg).split("\u0000")
          tmsg = String.new(tmsg).split("\u0000")

          translated_hash = {} of Int8 => String
          tmsg.each_with_index { |msg, i| translated_hash[i.to_i8] = msg }

          messages[msgid] = translated_hash
          messages[plural_msgid] = translated_hash
        else
          messages[String.new(msg)] = {0.to_i8 => String.new(tmsg)}
        end
      end

      return messages
    end

    # Create message catalogue from the loaded locale files.
    #
    # This is the equivalent to `parse` and is only here for compatibility with `Gettext::POBackend`
    #
    # This is returned as a mapping of the language code to the catalogue
    # in which the language code is taken from the `Language` header. If
    # none can be found then the mo file name is used as a fallback.
    #
    # ```
    # backend = Gettext::MOBackend.new("locales")
    # backend.create # => Hash(String, Catalogue)
    # ```
    def create : Hash(String, Catalogue)
      return self.parse
    end
  end
end
