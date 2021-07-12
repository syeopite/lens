module LensExceptions
  # Exception thrown when an error occurred during lexing.
  class LexError < Exception
    def self.new(file_name, message, full_line : String, line : Int, column : Int)
      error_message = String.build do |str|
        str << "An error occurred when scanning '#{file_name}' at Line #{line}:\n"
        str << "#{full_line.strip("\n")}\n"
        str << "#{" " * (column - 1)} ^\n"

        # If column is out of bounds then we won't show error location
        puts column, full_line.size, column >= full_line.size
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
end
