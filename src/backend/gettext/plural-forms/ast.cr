# Abstract syntax trees for representing gettext plural-form expressions
module PluralForm
  extend self

  private abstract class Expression
    abstract def accept(visitor)
  end

  # Object representing binary expression
  private class Binary < Expression
    getter left : Expression
    getter operator : Token
    getter right : Expression

    def initialize(@left, @operator, @right)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing an assignment expression
  private class Assignment < Expression
    getter name : String
    getter value : Expression

    def initialize(@name, @value)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a logical expression
  private class Logical < Expression
    getter left : Expression
    getter operator : Token
    getter right : Expression

    def initialize(@left, @operator, @right)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a conditional
  private class Conditional < Expression
    getter condition : Expression
    getter then_branch : Expression
    getter else_branch : Expression

    def initialize(@condition, @then_branch, @else_branch)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a expression grouping
  private class Grouping < Expression
    getter expression : Expression

    def initialize(@expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a unary expression
  private class Unary < Expression
    getter operator : Token
    getter right : Expression

    def initialize(@operator, @right)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a literal expression
  private class Literal < Expression
    getter value : String | Int32 | Int64 | Float64

    def initialize(@value)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a variable expression
  private class Variable < Expression
    getter name : String

    def initialize(@name)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  private abstract class ExpressionVisitor
    protected abstract def visit(expr : Binary)
    protected abstract def visit(expr : Assignment)
    protected abstract def visit(expr : Logical)
    protected abstract def visit(expr : Conditional)
    protected abstract def visit(expr : Grouping)
    protected abstract def visit(expr : Unary)
    protected abstract def visit(expr : Literal)
    protected abstract def visit(expr : Variable)
  end
end
