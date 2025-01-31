use Protoss

defprotocol Clr.Analysis.Allocator do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, block, config)
after
  defstruct []

  alias Clr.Air.Lvalue
  alias Clr.Type

  def transferred_msg(error) do
    if function = Map.get(error, :transferred) do
      "\nPointer was transferred to #{Lvalue.as_string(function)}"
    end
  end

  defmodule UseAfterFree do
    defexception [:function, :loc, :del_loc, :del_function, :transferred]

    alias Clr.Analysis.Allocator
    alias Clr.Zig.Parser

    def message(error) do
      function = Parser.format_location(error.function, error.loc)
      deletion = Parser.format_location(error.del_function, error.del_loc)

      """
      Use after free detected in #{function}.
      Pointer was deleted in #{deletion}#{Allocator.transferred_msg(error)}
      """
    end
  end

  defmodule DoubleFree do
    defexception [:previous, :prev_loc, :deletion, :loc, :transferred]

    alias Clr.Analysis.Allocator
    alias Clr.Zig.Parser

    def message(error) do
      deletion = Parser.format_location(error.deletion, error.loc)
      previous = Parser.format_location(error.previous, error.prev_loc)

      """
      Double free detected in #{deletion}.
      Previously deleted in #{previous}#{Allocator.transferred_msg(error)}
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
      Pointer was created in #{stack_info}
      """
    end

    def message(exception) do
      delete = Parser.format_location(exception.function, exception.loc)
      original = Lvalue.as_string(exception.original)
      attempted = Lvalue.as_string(exception.attempted)

      """
      Heap memory attempted to be freed by `#{attempted}` in #{delete}.
      Originally allocated by `#{original}`
      """
    end
  end

  defmodule CallDeleted do
    defexception [
      :function,
      :loc,
      :deleted_fn,
      :deleted_loc,
      :call,
      :index,
      :transferred
    ]

    alias Clr.Zig.Parser
    alias Clr.Analysis.Allocator

    def message(error) do
      function = Parser.format_location(error.function, error.loc)
      deletion = Parser.format_location(error.deleted_fn, error.deleted_loc)

      """
      Function call `#{error.call}` in #{function} was passed a deleted pointer (argument #{error.index}).
      Pointer was deleted in #{deletion}#{Allocator.transferred_msg(error)}
      """
    end
  end

  alias Clr.Air.Instruction.Function.Call
  alias Clr.Air.Instruction.Mem.Load

  @impl true
  def always, do: [Call, Load]

  @impl true
  def when_kept, do: []

  @impl true
  def on_call_requirement(block, type) do
    case Type.get_meta(type) do
      %{deleted: _} ->
        Type.put_meta(type, transferred: block.function)

      _ ->
        type
    end
  end
end

defimpl Clr.Analysis.Allocator, for: Clr.Air.Instruction.Function.Call do
  import Clr.Air.Lvalue

  alias Clr.Analysis.Undefined
  alias Clr.Analysis.Allocator.DoubleFree
  alias Clr.Analysis.Allocator.Mismatch
  alias Clr.Analysis.Allocator.CallDeleted
  alias Clr.Block
  alias Clr.Type

  @impl true
  def analyze(call, slot, block, config) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | _], type, _fn_opts}, {:function, "create_" <> _}} ->
        process_create(call.args, type, slot, block, config)

      {:literal, {:fn, [~l"mem.Allocator" | _], _, _fn_opts}, {:function, "destroy" <> _}} ->
        process_destroy(call.args, slot, block, config)

      _ ->
        check_passing_deleted(call, block, config)
    end
  end

  defp process_create(
         [{:literal, ~l"mem.Allocator", struct}],
         type,
         slot,
         block,
         _config
       ) do
    heapinfo = %{vtable: Map.fetch!(struct, "vtable"), function: block.function, loc: block.loc}

    {:errorunion, e, {:ptr, :one, payload_type, ptr_meta}, err_meta} = Type.from_air(type)

    block =
      Block.put_type(
        block,
        slot,
        {:errorunion, e,
         {:ptr, :one, Type.put_meta(payload_type, undefined: Undefined.meta(block)),
          Map.put(ptr_meta, :heap, heapinfo)}, err_meta}
      )

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
      {:ptr, :one, _type, %{deleted: %{function: prev_function, loc: prev_loc}} = meta} ->
        raise DoubleFree,
          previous: prev_function,
          prev_loc: prev_loc,
          deletion: this_function,
          loc: block.loc,
          transferred: Map.get(meta, :transferred)

      {:ptr, :one, _type, %{heap: %{vtable: ^vtable}}} ->
        deleted_info = %{function: this_function, loc: block.loc}
        {:halt, Block.update_type!(block, src, &Type.put_meta(&1, deleted: deleted_info))}

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
    {:literal, _, {:function, call_name}} = call.fn

    checked =
      call.args
      |> Enum.with_index()
      |> Enum.reduce(block, fn
        {{slot, _}, index}, block when is_integer(slot) ->
          # TODO: check other types and make sure none of them are deleted too.
          case Block.fetch_up!(block, slot) do
            {{:ptr, _, _, %{deleted: d} = meta}, _} ->
              raise CallDeleted,
                function: block.function,
                loc: block.loc,
                call: call_name,
                index: index,
                deleted_fn: d.function,
                deleted_loc: d.loc,
                transferred: Map.get(meta, :transferred)

            {_, block} ->
              block
          end

        _, block ->
          block
      end)

    {:cont, checked}
  end
end

# NB: there are many other instructions that need to have this implementation.
defimpl Clr.Analysis.Allocator, for: Clr.Air.Instruction.Mem.Load do
  alias Clr.Analysis.Allocator.UseAfterFree
  alias Clr.Block

  def analyze(%{src: {src_slot, _}}, _slot, block, _config) do
    case Block.fetch!(block, src_slot) do
      {:ptr, _, _, %{deleted: %{function: function, loc: loc}} = meta} ->
        raise UseAfterFree,
          del_function: function,
          del_loc: loc,
          function: block.function,
          loc: block.loc,
          transferred: Map.get(meta, :transferred)

      _ ->
        {:cont, block}
    end
  end
end
