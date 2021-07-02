# Abstract syntax trees for representing gettext plural-form expressions
module PluralForm
  extend self

  private abstract struct Expression
    abstract def accept(visitor)
  end

  # Object representing binary expression
  private struct Binary < Expression
    def initialize(@left, @operator, @right)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a logical expression
  private struct Logical < Expression
    def initialize(@left, @operator, @right)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a conditional
  private struct Conditional < Expression
    def initialize(@condition, @then_branch, @else_branch)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a expression grouping
  private struct Grouping < Expression
    def initialize(@expression)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a unary expression
  private struct Unary < Expression
    def initialize(@operator, @right)
    end

    def accept(visitor)
      visitor.visit(self)
    end
  end

  # Object representing a literal expression
  private struct Literal < Expression
    def initialize(@value)
    end

    def accept(vistior)
      visitor.visit(self)
    end
  end

  # Object representing a variable expression
  private struct Variable < Expression
    def initialize(@name)
    end

    def accept(vistior)
      visitor.visit(self)
    end
  end

  abstract class ExpressionVisitor
    abstract def visit(expr : Binary)
    abstract def visit(expr : Logical)
    abstract def visit(expr : Conditional)
    abstract def visit(expr : Grouping)
    abstract def visit(expr : Unary)
    abstract def visit(expr : Literal)
    abstract def visit(expr : Variable)
  end
end
