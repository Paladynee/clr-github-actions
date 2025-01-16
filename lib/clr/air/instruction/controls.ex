defmodule Clr.Air.Instruction.Controls do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[argument cs slotref lparen rparen type lvalue literal fn_literal rbrack lbrack clobbers space codeblock]a
  )

  Pegasus.parser_from_string(
    """
    controls <- return / block / loop / repeat / br / frame_addr / call
    """,
    controls: [export: true]
  )

  # returns

  Pegasus.parser_from_string(
    """
    return <- ret_ptr / ret_addr
    ret_ptr <- 'ret_ptr' lparen type rparen
    """,
    ret_ptr: [export: true, post_traverse: :ret_ptr]
  )

  defmodule RetPtr do
    defstruct [:type]
  end

  def ret_ptr(rest, [value, "ret_ptr"], context, _slot, _bytes) do
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

  defmodule Block do
    defstruct [:type, :code, clobbers: []]
  end

  Pegasus.parser_from_string(
    """
    block <- block_str lparen type cs codeblock (space clobbers)? rparen
    block_str <- 'block'
    """,
    block: [post_traverse: :block],
    block_str: [ignore: true]
  )

  def block(rest, [codeblock, type], context, _slot, _bytes) do
    {rest, [%Block{type: type, code: codeblock}], context}
  end

  def block(rest, [{:clobbers, clobbers}, codeblock, type], context, _slot, _bytes) do
    {rest, [%Block{type: type, code: codeblock, clobbers: clobbers}], context}
  end

  defmodule Loop do
    defstruct [:type, :code]
  end

  Pegasus.parser_from_string(
    """
    loop <- loop_str lparen type cs codeblock rparen
    loop_str <- 'loop'
    """,
    loop: [post_traverse: :loop],
    loop_str: [ignore: true]
  )

  def loop(rest, [codeblock, type], context, _slot, _bytes) do
    {rest, [%Loop{type: type, code: codeblock}], context}
  end

  defmodule Repeat do
    defstruct [:goto]
  end

  Pegasus.parser_from_string(
    """
    repeat <- repeat_str lparen slotref rparen
    repeat_str <- 'repeat'
    """,
    repeat: [post_traverse: :repeat],
    repeat_str: [ignore: true]
  )

  def repeat(rest, [goto], context, _slot, _bytes) do
    {rest, [%Repeat{goto: goto}], context}
  end

  defmodule Br do
    defstruct [:goto, :value]
  end

  Pegasus.parser_from_string(
    """
    br <- br_str lparen slotref cs argument rparen
    br_str <- 'br'
    """,
    br: [post_traverse: :br],
    br_str: [ignore: true]
  )

  def br(rest, [value, goto], context, _, _) do
    {rest, [%Br{goto: goto, value: value}], context}
  end

  defmodule Call do
    use Clr.Air.Instruction

    defstruct [:fn, :args]

    alias Clr.Block
    alias Clr.Type

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
    call <- call_str lparen (fn_literal / slotref) cs lbrack (argument (cs argument)*)? rbrack rparen
    call_str <- 'call'
    """,
    call: [post_traverse: :call],
    call_str: [ignore: true]
  )

  def call(rest, args, context, _, _) do
    case Enum.reverse(args) do
      [fun | args] ->
        {rest, [%Call{fn: fun, args: args}], context}
    end
  end
end
