# Specs for some helper function Lens uses
require "spec"
require "../src/helpers/helpers"

it "Able to do modulo operations on both ints and floats" do
  modulo(5, 3).should(eq(2))
  modulo(3, 5).should(eq(3))
  modulo(2.5, 5).should(eq(2.5))
  modulo(5, 2.5).should(eq(0))
  modulo(2.5, 1.2).round(1).should(eq(0.1))
end
