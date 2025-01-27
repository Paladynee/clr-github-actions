use Protoss

defprotocol Clr.Analysis.Allocator do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, block, config)
after
  defstruct []

  defmodule UseAfterFree do
    defexception [:function, :loc, :del_loc, :del_function]

    def message(%{
          function: function,
          del_function: function,
          loc: {row, col},
          del_loc: {del_row, del_col}
        }) do
      "Use after free detected in function `#{function}` at #{row}:#{col}, deleted at #{del_row}:#{del_col}"
    end

    def message(%{
          function: function,
          del_function: del_function,
          loc: {row, col},
          del_loc: {del_row, del_col}
        }) do
      "Use after free detected in function `#{function}` at #{row}:#{col}, function #{del_function} was passed the pointer at #{del_row}:#{del_col} and deletes it"
    end
  end

  defmodule DoubleFree do
    defexception [:previous, :prev_loc, :deletion, :loc, transferred: false]

    def message(
          %{
            previous: function,
            loc: {row, col},
            prev_loc: {prev_row, prev_col},
            transferred: true
          } =
            exception
        ) do
      "Double free detected in function `#{exception.deletion}` at #{row}:#{col}, function `#{function}` was passed the pointer at #{prev_row}:#{prev_col} and deletes it"
    end

    def message(%{
          previous: function,
          deletion: function,
          loc: {row, col},
          prev_loc: {prev_row, prev_col}
        }) do
      "Double free detected in function `#{function}` at #{row}:#{col}, previously deleted at #{prev_row}:#{prev_col}"
    end

    def message(%{loc: {row, col}} = exception) do
      "Double free detected in function `#{exception.deletion}` at #{row}:#{col}, function already deleted by `#{exception.previous}`"
    end
  end

  defmodule Mismatch do
    defexception [:original, :attempted, :function, :loc]

    def message(%{original: {:stack, function, {srow, scol}}, loc: {row, col}} = exception) do
      "Stack memory (of #{function} created at #{srow}:#{scol}) attempted to be freed by `#{exception.attempted}` in `#{exception.function}` at #{row}:#{col}"
    end

    def message(%{loc: {row, col}} = exception) do
      "Heap memory allocated by `#{exception.original}` freed by `#{exception.attempted}` in `#{exception.function}` at #{row}:#{col}"
    end
  end

  defmodule CallDeleted do
    defexception [:function, :loc, :deleted_loc, :transferred_function]

    def message(%{
          function: function,
          loc: {row, col},
          transferred_function: nil,
          deleted_loc: {del_row, del_col}
        }) do
      "Function `#{function}` at #{row}:#{col} called with a deleted pointer at #{del_row}:#{del_col}"
    end

    def message(%{
          function: function,
          loc: {row, col},
          transferred_function: transferred_function,
          deleted_loc: {del_row, del_col}
        }) do
      "Function `#{function}` at #{row}:#{col} called with a pointer that was transferred to `#{transferred_function}` at #{del_row}:#{del_col}"
    end
  end

  alias Clr.Air.Instruction.Function.Call
  alias Clr.Air.Instruction.Mem.Load

  @impl true
  def always, do: [Call, Load]

  @impl true
  def when_kept, do: []
end

defimpl Clr.Analysis.Allocator, for: Clr.Air.Instruction.Function.Call do
  alias Clr.Type

  import Clr.Air.Lvalue

  alias Clr.Analysis.Undefined
  alias Clr.Analysis.Allocator.DoubleFree
  alias Clr.Analysis.Allocator.Mismatch
  alias Clr.Analysis.Allocator.CallDeleted
  alias Clr.Block

  @impl true
  def analyze(call, slot, block, config) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | _], _, _fn_opts}, {:function, "create_" <> _}} ->
        process_create(call.args, slot, block, config)

      {:literal, {:fn, [~l"mem.Allocator" | _], _, _fn_opts}, {:function, "destroy" <> _}} ->
        process_destroy(call.args, slot, block, config)

      _ ->
        check_passing_deleted(call, block, config)
    end
  end

  defp process_create(
         [{:literal, ~l"mem.Allocator", struct}],
         slot,
         block,
         _config
       ) do
    heapinfo = %{vtable: Map.fetch!(struct, "vtable"), function: block.function, loc: block.loc}

    block =
      Block.update_type!(block, slot, fn
        {:errorunion, e, {:ptr, :one, type, ptr_meta}, err_meta} ->
          {:errorunion, e,
           {:ptr, :one, Type.put_meta(type, undefined: Undefined.meta(block)),
            Map.put(ptr_meta, :heap, heapinfo)}, err_meta}
      end)

    {:halt, block}
  end

  defp process_destroy([{:literal, ~l"mem.Allocator", struct}, {src, _}], _slot, block, _config) do
    vtable = Map.fetch!(struct, "vtable")
    this_function = block.function

    # TODO: consider only flushing the awaits that the function needs.
    block = Block.flush_awaits(block)

    block
    |> Block.fetch!(src)
    |> case do
      {:ptr, :one, _type, %{deleted: %{function: prev_function, loc: prev_loc}}} ->
        raise DoubleFree,
          previous: prev_function,
          prev_loc: prev_loc,
          deletion: this_function,
          loc: block.loc

      {:ptr, :one, _type, %{transferred: %{function: prev_function, loc: prev_loc}}} ->
        raise DoubleFree,
          previous: prev_function,
          prev_loc: prev_loc,
          deletion: this_function,
          loc: block.loc

      {:ptr, :one, _type, %{heap: %{vtable: ^vtable}}} ->
        deleted_info = %{function: this_function, loc: block.loc}
        {:halt, Block.put_meta(block, src, deleted: deleted_info)}

      {:ptr, :one, _type, %{heap: other}} ->
        raise Mismatch,
          original: other.vtable,
          attempted: vtable,
          function: this_function,
          loc: block.loc

      {:ptr, :one, _type, %{stack: %{function: function, loc: loc}}} ->
        raise Mismatch,
          original: {:stack, function, loc},
          attempted: vtable,
          function: this_function,
          loc: block.loc

      _ ->
        {:cont, block}
    end
  end

  defp check_passing_deleted(call, block, _config) do
    Enum.reduce(call.args, block, fn {slot, _}, block ->
      # TODO: check other types and make sure none of them are deleted too.
      case Block.fetch!(block, slot) do
        {:ptr, _, _, %{deleted: d}} ->
          raise CallDeleted,
            function: block.function,
            loc: block.loc,
            deleted_loc: d.loc

        {:ptr, _, _, %{transferred: t}} ->
          raise CallDeleted,
            function: block.function,
            loc: block.loc,
            transferred_function: t.function,
            deleted_loc: t.loc

        _ ->
          {:cont, block}
      end
    end)
  end
end

defimpl Clr.Analysis.Allocator, for: Clr.Air.Instruction.Mem.Load do
  alias Clr.Analysis.Allocator.UseAfterFree
  alias Clr.Block

  def analyze(%{src: {src_slot, _}}, _slot, block, _config) do
    case Block.fetch!(block, src_slot) do
      {:ptr, _, _, %{deleted: %{function: function, loc: loc}}} ->
        raise UseAfterFree,
          del_function: function,
          del_loc: loc,
          function: block.function,
          loc: block.loc

      {:ptr, _, _, %{transferred: %{function: function, loc: loc}}} ->
        raise UseAfterFree,
          del_function: function,
          del_loc: loc,
          function: block.function,
          loc: block.loc

      _ ->
        {:cont, block}
    end
  end
end
