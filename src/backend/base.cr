module Base
  class Backend
    def initialize(@path : String)
      @had_error = false
    end

    private def load
    end
  end

  abstract struct Token
    property token_type, lexeme, literal, line
  end
end
