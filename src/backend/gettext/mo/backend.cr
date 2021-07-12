module Gettext
  extend self

  # The backend for Gettext's MO files. This class contains methods to parse and interact with them.
  class MOBackend
    LE_MAGIC = 0x950412de
    BE_MAGIC = 0xde120495

    # Create a new MO backend instance that reads from the given locale directory path
    #
    # ```
    # Gettext::POBackend.new("locales")
    # ```
    def initialize(@locale_directory_path : String)
      @had_error = false
      @_source = {} of String => File

      Dir.glob("#{@locale_directory_path}/*.mo") do |gettext_file|
        name = File.basename(gettext_file)
        @_source[name] = File.open(gettext_file)
      end
    end

    # Parse gettext mo files into message catalogues
    #
    # ```
    # backend = Gettext::MOBackend.new("locales")
    # backend.parse
    # ```
    def parse
      if @_source.empty?
        raise Exception.new("No locale files have been loaded yet. Did you forget to call
                             the .load() method?")
      end

      locale_catalogues = {} of String => Catalogue
      @_source.each do |file_name, io|
        catalogue = {} of String => Hash(Int8, String)
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

            catalogue[msgid] = translated_hash
            catalogue[plural_msgid] = translated_hash
          else
            catalogue[String.new(msg)] = {0.to_i8 => String.new(tmsg)}
          end
        end

        locale_catalogues[file_name] = Catalogue.new(catalogue)
      end

      return locale_catalogues
    end
  end
end
