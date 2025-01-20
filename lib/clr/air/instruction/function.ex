defmodule Clr.Air.Instruction.Function do
  require Pegasus
  require Clr.Air
  alias Clr.Block
  alias Clr.Type

  Clr.Air.import(~w[type int cs dquoted lparen rparen argument fn_literal lbrack rbrack slotref]a)

  Pegasus.parser_from_string(
    "function <- arg / call / ret_info / ret / frame_addr ",
    function: [export: true]
  )

  defmodule Arg do
    defstruct [:type, :name]

    use Clr.Air.Instruction

    def analyze(%{type: type}, slot, block) do
      # note that metadata is conveyed through the args_meta
      arg_meta = Enum.at(block.args_meta, slot) || raise "unreachable"
      Block.put_type(block, slot, Type.from_air(type), arg_meta)
    end
  end

  Pegasus.parser_from_string(
    """
    arg <- arg_str lparen type (cs dquoted)? rparen
    arg_str <- 'arg'
    """,
    arg: [post_traverse: :arg],
    arg_str: [ignore: true]
  )

  def arg(rest, [type], context, _slot, _byte) do
    {rest, [%Arg{type: type}], context}
  end

  def arg(rest, [name, type], context, _slot, _byte) do
    {rest, [%Arg{type: type, name: name}], context}
  end

  defmodule Call do
    use Clr.Air.Instruction

    defstruct [:fn, :args, :opt]

    alias Clr.Block
    alias Clr.Type
    alias Clr.Function

    import Clr.Air.Lvalue

    def analyze(call, slot, block) do
      case call.fn do
        {:literal, {:fn, [~l"mem.Allocator" | params], type, _fn_opts}, {:function, function}} ->
          process_allocator(function, params, type, call.args, slot, block)

        {:literal, _type, {:function, function_name}} ->
          # we also need the context of the current function.

          {metas_slots, block} =
            Enum.map_reduce(call.args, block, fn
              {:literal, _type, _}, block ->
                {{%{}, nil}, block}

              {slot, _}, block ->
                {type, block} = Block.fetch_up!(block, slot)
                {{Type.get_meta(type), slot}, block}
            end)

          {args_meta, slots} = Enum.unzip(metas_slots)

          block.function
          |> merge_name(function_name)
          |> Function.evaluate(args_meta, slots)
          |> case do
            {:future, ref} ->
              Block.put_await(block, slot, ref)

            {:ok, result} ->
              Block.put_type(block, slot, result)
          end
      end
    end

    defp process_allocator(
           "create" <> _,
           [],
           {:errorable, e, {:ptr, _, _, _} = ptr_type},
           [{:literal, ~l"mem.Allocator", struct}],
           slot,
           analysis
         ) do
      type =
        ptr_type
        |> Type.from_air()
        |> Type.put_meta(heap: Map.fetch!(struct, "vtable"))
        |> then(&{:errorable, e, &1, %{}})

      Block.put_type(analysis, slot, type)
    end

    defp process_allocator(
           "destroy" <> _,
           [_],
           ~l"void",
           [{:literal, ~l"mem.Allocator", struct}, {src, _}],
           slot,
           block
         ) do
      vtable = Map.fetch!(struct, "vtable")
      this_function = block.function

      # TODO: consider only flushing the awaits that the function needs.
      block
      |> Block.flush_awaits()
      |> Block.fetch_up!(src)
      |> case do
        {{:ptr, :one, _type, %{deleted: prev_function}}, block} ->
          raise Clr.DoubleFreeError,
            previous: Clr.Air.Lvalue.as_string(prev_function),
            deletion: Clr.Air.Lvalue.as_string(this_function),
            loc: block.loc

        {{:ptr, :one, _type, %{heap: ^vtable}}, block} ->
          block
          |> Block.put_meta(src, deleted: this_function)
          |> Block.put_type(slot, Type.void())

        {{:ptr, :one, _type, %{heap: other}}, block} ->
          raise Clr.AllocatorMismatchError,
            original: Clr.Air.Lvalue.as_string(other),
            attempted: Clr.Air.Lvalue.as_string(vtable),
            function: Clr.Air.Lvalue.as_string(this_function),
            loc: block.loc

        _ ->
          raise Clr.AllocatorMismatchError,
            original: :stack,
            attempted: Clr.Air.Lvalue.as_string(vtable),
            function: Clr.Air.Lvalue.as_string(this_function),
            loc: block.loc
      end
    end

    # utility functions

    defp merge_name({:lvalue, lvalue}, function_name) do
      {:lvalue, List.replace_at(lvalue, -1, function_name)}
    end
  end

  Pegasus.parser_from_string(
    """
    call <- call_str (always_tail / never_tail / never_inline)? 
      lparen (fn_literal / slotref) cs lbrack (argument (cs argument)*)? rbrack rparen
    call_str <- 'call'
    always_tail <- '_always_tail'
    never_tail <- '_never_tail'
    never_inline <- '_never_inline'
    """,
    call: [post_traverse: :call],
    call_str: [ignore: true],
    always_tail: [token: :always_tail],
    never_tail: [token: :never_tail],
    never_inline: [token: :never_inline]
  )

  @call_opts ~w[always_tail never_tail never_inline]a

  def call(rest, args, context, _, _) do
    case Enum.reverse(args) do
      [opt, fun | args] when opt in @call_opts ->
        {rest, [%Call{fn: fun, args: args, opt: opt}], context}

      [fun | args] ->
        {rest, [%Call{fn: fun, args: args}], context}
    end
  end

  defmodule Ret do
    defstruct [:val, :mode]

    use Clr.Air.Instruction

    alias Clr.Block

    def analyze(%{mode: :safe, val: {:lvalue, _} = lvalue}, _dst_slot, block) do
      Block.put_return(block, {:TypeOf, lvalue})
    end

    def analyze(%{mode: :safe, val: {:literal, type, _}}, _dst_slot, block) do
      Block.put_return(block, type)
    end

    def analyze(%{mode: :safe, val: {src_slot, _}}, _dst_slot, %{function: function} = block) do
      case Block.fetch_up!(block, src_slot) do
        {{:ptr, _, _, %{stack: ^function}}, block} ->
          raise Clr.StackPtrEscape,
            function: Clr.Air.Lvalue.as_string(function),
            loc: block.loc

        {type, block} ->
          Block.put_return(block, type)
      end
    end
  end

  Pegasus.parser_from_string(
    """
    ret <- ret_str (safe / load)? lparen argument rparen
    ret_str <- 'ret'
    safe <- '_safe'
    load <- '_load'
    """,
    ret: [post_traverse: :ret],
    ret_str: [ignore: true],
    safe: [token: :safe],
    load: [token: :load]
  )

  def ret(rest, [value | rest_args], context, _slot, _bytes) do
    mode =
      case rest_args do
        [:safe] -> :safe
        [:load] -> :load
        [] -> nil
      end

    {rest, [%Ret{val: value, mode: mode}], context}
  end

  Pegasus.parser_from_string(
    """
    ret_info <- ret_ptr / ret_addr
    ret_ptr <- ret_ptr_str lparen type rparen
    ret_ptr_str <- 'ret_ptr'
    """,
    ret_ptr: [post_traverse: :ret_ptr],
    ret_ptr_str: [ignore: true]
  )

  defmodule RetPtr do
    defstruct [:type]
  end

  def ret_ptr(rest, [value], context, _slot, _bytes) do
    {rest, [%RetPtr{type: value}], context}
  end

  defmodule RetAddr do
    defstruct []
  end

  Pegasus.parser_from_string(
    """
    ret_addr <- ret_addr_str
    ret_addr_str <- 'ret_addr()'
    """,
    ret_addr: [post_traverse: :ret_addr],
    ret_addr_str: [ignore: true]
  )

  def ret_addr(rest, [], context, _, _) do
    {rest, [%RetAddr{}], context}
  end

  defmodule FrameAddr do
    defstruct []
  end

  Pegasus.parser_from_string(
    """
    frame_addr <- frame_addr_str
    frame_addr_str <- 'frame_addr()'
    """,
    frame_addr: [post_traverse: :frame_addr],
    frame_addr_str: [ignore: true]
  )

  def frame_addr(rest, [], context, _, _) do
    {rest, [%FrameAddr{}], context}
  end
end
