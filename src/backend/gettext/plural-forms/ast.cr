# Abstract syntax trees for representing gettext plural-form expressions
module PluralForm
  extend self

  private abstract class Expression
    abstract def accept(visitor)
  end

  # Object representing binary expression
  private class Binary < Expression
    def initialize(@left : Expression, @operator : Token, @right : Expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing an assignment expression
  private class Assignment < Expression
    def initialize(@name : String, @value : Expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a logical expression
  private class Logical < Expression
    def initialize(@left : Expression, @operator : Token, @right : Expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a conditional
  private class Conditional < Expression
    def initialize(@condition : Expression, @then_branch : Expression, @else_branch : Expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a expression grouping
  private class Grouping < Expression
    def initialize(@expression : Expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a unary expression
  private class Unary < Expression
    def initialize(@operator : Token, @right : Expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a literal expression
  private class Literal(T) < Expression
    def initialize(@value : T)
    end

    def accept(vistior)
      visitor.visit(self)
    end
  end

  # Object representing a variable expression
  private class Variable < Expression
    getter name : String

    def initialize(@name)
    end

    def accept(vistior)
      visitor.visit(self)
    end
  end

  private abstract class ExpressionVisitor
    abstract def visit(expr : Binary)
    abstract def visit(expr : Logical)
    abstract def visit(expr : Conditional)
    abstract def visit(expr : Grouping)
    abstract def visit(expr : Unary)
    abstract def visit(expr : Literal)
    abstract def visit(expr : Variable)
  end
end
