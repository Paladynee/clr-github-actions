use Protoss

defprotocol Clr.Analysis.Allocator do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, block, config)
after
  defstruct []

  defmodule UseAfterFree do
    defexception [:function, :loc, :del_loc, :del_function]

    alias Clr.Zig.Parser

    def message(%{
          function: function,
          del_function: del_function,
          loc: loc,
          del_loc: del_loc
        }) do
      function = Parser.format_location(function, loc)
      deletion = Parser.format_location(del_function, del_loc)

      """
      Use after free detected in #{function}.
      Pointer was deleted in #{deletion}
      """
    end
  end

  defmodule DoubleFree do
    defexception [:previous, :prev_loc, :deletion, :loc, transferred: false]

    alias Clr.Zig.Parser

    def message(exception) do
      deletion = Parser.format_location(exception.deletion, exception.loc)
      previous = Parser.format_location(exception.previous, exception.prev_loc)

      """
      Double free detected in #{deletion}.
      Previously deleted in #{previous}
      """
    end
  end

  defmodule Mismatch do
    defexception [:original, :attempted, :function, :loc]
    alias Clr.Zig.Parser
    alias Clr.Air.Lvalue

    def message(%{original: {:stack, function, sloc}} = exception) do
      stack_info = Parser.format_location(function, sloc)
      delete_info = Parser.format_location(exception.function, exception.loc)

      """
      Stack memory attempted to be freed by allocator `#{Lvalue.as_string(exception.attempted)} in #{delete_info}.
      Pointer was created from #{stack_info}
      """
    end

    def message(exception) do
      delete = Parser.format_location(exception.function, exception.loc)
      original = Lvalue.as_string(exception.original)
      attempted = Lvalue.as_string(exception.attempted)

      """
      Heap memory attempted to be freed by `#{attempted}` originally allocated by `#{original}` in #{delete}
      """
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
      case Block.fetch_up!(block, slot) do
        {{:ptr, _, _, %{deleted: d}}, _} ->
          raise CallDeleted,
            function: block.function,
            loc: block.loc,
            deleted_loc: d.loc

        {{:ptr, _, _, %{transferred: t}}, _} ->
          raise CallDeleted,
            function: block.function,
            loc: block.loc,
            transferred_function: t.function,
            deleted_loc: t.loc

        {_, block} ->
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
