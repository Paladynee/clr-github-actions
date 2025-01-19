defmodule Clr.Air.Instruction.ControlFlow do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[argument cs slotref lparen rparen type lvalue literal fn_literal rbrack lbrack clobbers space codeblock
      codeblock_clobbers fatarrow elision newline]a
  )

  Pegasus.parser_from_string(
    """
    control_flow <- ret / ret_info / block / loop / repeat / br / frame_addr / call / cond_br / switch_br / 
      try / try_ptr / unreach
    """,
    control_flow: [export: true]
  )

  # returns

  Pegasus.parser_from_string(
    """
    ret_info <- ret_ptr / ret_addr
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

    defstruct [:fn, :args, :opt]

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

  defmodule CondBr do
    defstruct [:cond, :true_branch, :false_branch]
  end

  Pegasus.parser_from_string(
    """
    cond_br <- 'cond_br' lparen slotref cs branch cs branch rparen

    branch <- branchtype space codeblock_clobbers
    branchtype <- likelypoi / unlikelypoi / coldpoi / likely / unlikely / cold / poi 

    poi <- 'poi'
    likely <- 'likely'
    unlikely <- 'unlikely'
    cold <- 'cold'
    likelypoi <- 'likely poi'
    unlikelypoi <- 'unlikely poi'
    coldpoi <- 'cold poi'
    """,
    cond_br: [export: true, post_traverse: :cond_br],
    poi: [token: :poi],
    likely: [token: :likely],
    cold: [token: :cold],
    likelypoi: [token: :likelypoi],
    coldpoi: [token: :coldpoi],
    unlikely: [token: :unlikely],
    unlikelypoi: [token: :unlikelypoi]
  )

  def cond_br(
        rest,
        [false_branch, _false_type, true_branch, _true_type, slotref, "cond_br"],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%CondBr{cond: slotref, true_branch: true_branch, false_branch: false_branch}],
     context}
  end

  defmodule SwitchBr do
    defstruct [:test, :cases]
  end

  Pegasus.parser_from_string(
    """
    switch_br <- switch_br_str lparen slotref (cs switch_case)* (cs else_case)? (newline space*)? rparen

    switch_case <- lbrack case_value (cs case_value)* rbrack (space modifier)? space fatarrow space codeblock_clobbers 
    case_value <- range / literal / lvalue
    else_case <- else (space modifier)? space fatarrow space codeblock_clobbers

    range <- (literal / lvalue) elision (literal / lvalue)

    modifier <- cold / unlikely

    switch_br_str <- 'switch_br'
    else <- 'else'

    unlikely <- '.unlikely'
    cold <- '.cold'
    """,
    switch_br: [export: true, post_traverse: :switch_br],
    switch_br_str: [ignore: true],
    else: [token: :else],
    switch_case: [post_traverse: :switch_case],
    else_case: [post_traverse: :else_case],
    cold: [token: :cold],
    unlikely: [token: :unlikely]
  )

  defp switch_br(rest, args, context, _slot, _bytes) do
    case Enum.reverse(args) do
      [test | cases] ->
        {rest, [%SwitchBr{test: test, cases: Map.new(cases)}], context}
    end
  end

  @modifiers ~w[cold unlikely]a

  defp switch_case(rest, [codeblock, modifier | compares], context, _slot, _bytes)
       when modifier in @modifiers do
    {rest, [{compares, codeblock}], context}
  end

  defp switch_case(rest, [codeblock, rhs, :..., lhs], context, _slot, _bytes) do
    {rest, [{{:range, lhs, rhs}, codeblock}], context}
  end

  defp switch_case(rest, [codeblock | compares], context, _slot, _bytes) do
    {rest, [{compares, codeblock}], context}
  end

  defp else_case(rest, [codeblock, modifier, :else], context, _slot, _bytes)
       when modifier in @modifiers do
    {rest, [{:else, codeblock}], context}
  end

  defp else_case(rest, [codeblock, :else], context, _slot, _bytes) do
    {rest, [{:else, codeblock}], context}
  end

  defmodule Try do
    defstruct [:src, :error_code, clobbers: [], ptr: false, cold: false]

    use Clr.Air.Instruction
    alias Clr.Block

    def analyze(%{src: {src, _}}, slot, block) do
      {{:errorable, _, payload, _meta}, block} = Block.fetch_up!(block, src)
      # for now.  Ultimately, we will need to walk the analysis on this, too.
      Block.put_type(block, slot, payload)
    end
  end

  Pegasus.parser_from_string(
    """
    try <- try_str cold_mod? lparen slotref cs codeblock_clobbers (space clobbers)? rparen

    try_str <- 'try'
    cold_mod <- '_cold'
    """,
    try: [post_traverse: :try],
    try_str: [ignore: true],
    cold_mod: [token: :cold]
  )

  defp try(rest, [{:clobbers, clobbers}, error_code, src | maybe_cold], context, _slot, _bytes) do
    {rest, [%Try{src: src, error_code: error_code, clobbers: clobbers, cold: cold?(maybe_cold)}],
     context}
  end

  defp cold?([:cold]), do: true
  defp cold?([]), do: false

  defmodule TryPtr do
    defstruct [:src, :type, :error_code, clobbers: [], cold: false]

    use Clr.Air.Instruction
    alias Clr.Block

    def analyze(%{src: {src, _}}, slot, block) do
      {{:errorable, _, payload, _meta}, block} = Block.fetch_up!(block, src)
      # for now.  Ultimately, we will need to walk the analysis on this, too.
      Block.put_type(block, slot, payload)
    end
  end

  Pegasus.parser_from_string(
    """
    # NB: cold_mod is in the previous parser

    try_ptr <- try_ptr_str cold_mod? lparen slotref cs codeblock_clobbers (space clobbers)? rparen

    try_ptr_str <- 'try_ptr'
    """,
    try: [post_traverse: :try],
    try_ptr_str: [ignore: true]
  )

  defp try(rest, [{:clobbers, clobbers}, error_code, src | maybe_cold], context, _slot, _bytes) do
    {rest,
     [%TryPtr{src: src, error_code: error_code, clobbers: clobbers, cold: cold?(maybe_cold)}],
     context}
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

  defmodule Unreach do
    defstruct []
  end

  Pegasus.parser_from_string(
    """
    unreach <- unreach_str
    unreach_str <- 'unreach()'  
    """,
    unreach: [post_traverse: :unreach],
    unreach_str: [ignore: true]
  )

  def unreach(rest, [], context, _, _) do
    {rest, [%Unreach{}], context}
  end
end
