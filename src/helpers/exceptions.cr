# Contains all the exceptions lens would throw
module LensExceptions
  # Exception thrown when an error occurrs during lexing.
  class LexError < Exception
    def self.new(file_name, message, full_line : String, line : Int, column : Int)
      error_message = String.build do |str|
        str << "An error occurred when scanning '#{file_name}' at Line #{line}:\n"
        str << "#{full_line.strip("\n")}\n"
        str << "#{" " * (column - 1)}^\n"

        # If column is out of bounds then we won't show error location
        if column >= full_line.size
          str << "#{message} at column #{column}"
        else
          str << "#{message}: '#{full_line[column]}' at column #{column}\n"
        end
      end

      instance = LexError.allocate
      instance.initialize(error_message)
      return instance
    end
  end

  # Exception thrown when an error occurs during parsing
  class ParseError < Exception
  end

  # Exception thrown when an translation is messing. Only applies to certain formats by default
  class MissingTranslation < Exception
  end
end
