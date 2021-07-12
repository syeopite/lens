require "../../../helpers/*"

module PluralForm
  extend self

  # A interpreter that calculates the plural-form to take from the given expression trees and a number.
  #
  # [Based on this interpreter from crafting interpreters](https://craftinginterpreters.com/evaluating-expressions.html)
  class Interpreter < ExpressionVisitor
    # Creates an interpreter with the given expression trees
    #
    # ```
    # plural_form_scanner = PluralForm::Scanner.new("nplurals=2; plural=(n > 1);")
    # expressions = PluralForm::Parser.new(plural_form_scanner.scan).parse
    # interpreter = PluralForm::Interpreter.new(expressions)
    # interpreter.interpret(1)  # => 0
    # interpreter.interpret(50) # => 1
    # ```
    def initialize(@expressions : Array(Expression))
      # We don't really need scope for something like this
      @environment = {} of String => Int32 | Int64 | Float64
    end

    # Interpret Binary expression
    protected def visit(expr : Binary)
      left, right = self.evaluate(expr.left), self.evaluate(expr.right)
      left, right = self.check_number_operands(expr.operator, left, right)

      case expr.operator.token_type
      when TokenTypes::MINUS
        return left - right
      when TokenTypes::PLUS
        return left + right
      when TokenTypes::SLASH
        return left / right
      when TokenTypes::STAR
        return left * right
      when TokenTypes::MOD
        # Crystal does not support modulos between ints and floats
        # So we'll use an helper function that provides conversations between
        # ints and floats to allow for this operation
        return modulo(left, right)
      when TokenTypes::GREATER
        return left > right
      when TokenTypes::GREATER_EQUAL
        return left >= right
      when TokenTypes::LESS
        return left < right
      when TokenTypes::LESS_EQUAL
        return left <= right
      when TokenTypes::NOT_EQUAL
        return left != right
      when TokenTypes::EQUAL_EQUAL
        return left == right
      end
    end

    # Interpret assignment expression
    protected def visit(expr : Assignment)
      value = self.evaluate(expr.value)
      value = value.to_unsafe.to_i if value.is_a? Bool
      @environment[expr.name] = value.as(Int32 | Int64 | Float64)
      return value
    end

    # Interpet logical expression
    protected def visit(expr : Logical)
      left = self.evaluate(expr.left)

      case expr.operator.token_type
      when TokenTypes::OR
        return true if self.is_truthy(left)
      when TokenTypes::AND
        return false if !self.is_truthy(left)
      end

      return self.evaluate(expr.right)
    end

    # Interpret conditional expression
    protected def visit(expr : Conditional)
      if self.is_truthy(self.evaluate(expr.condition))
        return self.evaluate(expr.then_branch)
      else
        return self.evaluate(expr.else_branch)
      end
    end

    # Interpret grouping expression
    protected def visit(expr : Grouping)
      return self.evaluate(expr.expression)
    end

    # Interpret unary expression
    protected def visit(expr : Unary)
      right = self.evaluate(expr.right)

      right = self.check_number_operand(expr.operator, right)
      if expr.operator.token_type == TokenTypes::MINUS
        return -right
      elsif expr.operator.token_type == TokenTypes::NOT
        return !self.is_truthy(right)
      end
    end

    # Interpret literal expression
    protected def visit(expr : Literal)
      return expr.value
    end

    # Interpret variable expression
    protected def visit(expr : Variable)
      return @environment[expr.name]
    end

    # Validate that the given operand is a number.
    #
    # As we can only lex numbers for plural-forms this method
    # is only used to inform the compiler that the values are numbers
    private def check_number_operand(operator, operand)
      if operand.is_a? Int32 | Int64 | Float64
        return operand
      else
        raise Exception.new("Unreachable")
        # raise Exception.new("Operand must be a number at #{operator.column}")
      end
    end

    # Validate that the given operands are numbers
    #
    # As we can only lex numbers for plural-forms this method
    # is only used to inform the compiler that the values are numbers
    private def check_number_operands(operator, left, right)
      if left.is_a? Int32 | Int64 | Float64 && right.is_a? Int32 | Int64 | Float64
        return left, right
      else
        raise Exception.new("Unreachable")
        # raise Exception.new("Operands must be a numbers at #{operator.column}")
      end
    end

    # Evaluate the truthfulness for certain values
    #
    # Different from Crystal's own truthfulness measures as an 0 is considered
    private def is_truthy(value)
      if value == 0
        return false
      elsif value.is_a? Bool
        return value
      else
        return true
      end
    end

    # Evaluate an expression via the visitor pattern
    private def evaluate(expr)
      return expr.accept(self)
    end

    # Calculates which plural form to use for the given number
    def interpret(number)
      self.assign_plural(number)

      @expressions.each do |expr|
        self.evaluate(expr)
      end

      return @environment["plural"]
    end

    # Adds the given number as a variable for the plural-form expression to read from
    private def assign_plural(number : Int32 | Int64 | Float64)
      self.evaluate(Assignment.new("n", Literal.new(number)))
    end
  end
end
