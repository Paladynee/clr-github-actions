defmodule Clr.StackPtrEscape do
  defexception [:function, :row, :col]

  def message(exception) do
    "Stack pointer escape detected in function `#{exception.function}` at #{exception.row}:#{exception.col}"
  end
end

defmodule Clr.UndefinedUsage do
  defexception [:function, :row, :col]

  def message(exception) do
    "Undefined value used in function `#{exception.function}` at #{exception.row}:#{exception.col}"
  end
end

defmodule Clr.UseAfterFreeError do
  defexception [:function, :row, :col]

  def message(exception) do
    "Use after free detected in function `#{exception.function}` at #{exception.row}:#{exception.col}"
  end
end

defmodule Clr.DoubleFreeError do
  defexception [:function, :row, :col]

  def message(exception) do
    "Double free detected in function `#{exception.function}` at #{exception.row}:#{exception.col}"
  end
end

defmodule Clr.AllocatorMismatchError do
  defexception [:original, :attempted, :function, :row, :col]

  def message(%{original: :stack} = exception) do
    "Stack memory attempted to be freed by `#{exception.attempted}` in `#{exception.function}` at #{exception.row}:#{exception.col}"
  end

  def message(exception) do
    "Heap memory allocated by `#{exception.original}` freed by `#{exception.attempted}` in `#{exception.function}` at #{exception.row}:#{exception.col}"
  end
end
