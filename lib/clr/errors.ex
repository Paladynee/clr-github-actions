defmodule Clr.StackPtrEscape do
  defexception [:function, :loc]

  def message(%{loc: {row, col}} = exception) do
    "Stack pointer escape detected in function `#{exception.function}` at #{row}:#{col}"
  end
end

defmodule Clr.UndefinedUsage do
  defexception [:function, :loc]

  def message(%{loc: {row, col}} = exception) do
    "Undefined value used in function `#{exception.function}` at #{row}:#{col}"
  end
end

defmodule Clr.UseAfterFreeError do
  defexception [:function, :loc]

  def message(%{loc: {row, col}} = exception) do
    "Use after free detected in function `#{exception.function}` at #{row}:#{col}"
  end
end

defmodule Clr.DoubleFreeError do
  defexception [:previous, :deletion, :loc]

  def message(%{previous: function, deletion: function, loc: {row, col}}) do
    "Double free detected in function `#{function}` at #{row}:#{col}"
  end

  def message(%{loc: {row, col}} = exception) do
    "Double free detected in function `#{exception.deletion}` at #{row}:#{col}, function already deleted by `#{exception.previous}`"
  end
end

defmodule Clr.AllocatorMismatchError do
  defexception [:original, :attempted, :function, :loc]

  def message(%{original: :stack, loc: {row, col}} = exception) do
    "Stack memory attempted to be freed by `#{exception.attempted}` in `#{exception.function}` at #{row}:#{col}"
  end

  def message(%{loc: {row, col}} = exception) do
    "Heap memory allocated by `#{exception.original}` freed by `#{exception.attempted}` in `#{exception.function}` at #{row}:#{col}"
  end
end
