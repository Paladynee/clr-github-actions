defmodule Clr.StackPtrEscape do
  defexception [:function, :line, :col]

  def message(exception) do
    "Stack pointer escape detected in function `#{exception.function}` at #{exception.line}:#{exception.col}"
  end
end

defmodule Clr.UndefinedUsage do
  defexception [:function, :line, :col]

  def message(exception) do
    "Undefined value used in function `#{exception.function}` at #{exception.line}:#{exception.col}"
  end
end
