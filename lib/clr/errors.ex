defmodule Clr.StackPtrEscape do
  defexception [:function, :line, :col]

  def message(exception) do
    "Stack pointer escape detected in function `#{exception.function}` at #{exception.line}:#{exception.col}"
  end
end
