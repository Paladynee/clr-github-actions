defmodule Clr.Air.Instruction.ControlFlow do
  alias Clr.Air

  require Pegasus
  require Air

  Air.import(
    ~w[argument cs slotref lparen rparen type lvalue literal fn_literal rbrack lbrack clobbers space codeblock
      codeblock_clobbers fatarrow elision newline]a
  )

  Pegasus.parser_from_string(
    "control_flow <- block / loop / repeat / br / cond_br / switch_br / switch_dispatch / try_ptr / try / unreach",
    control_flow: [export: true]
  )

  defmodule Block do
    # Uses the `ty_pl` field with payload `Block`.  A block runs its body which always ends
    # with a `noreturn` instruction, so the only way to proceed to the code after the `block`
    # is to encounter a `br` that targets this `block`.  If the `block` type is `noreturn`,
    # then there do not exist any `br` instructions targeting this `block`.

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

  def block(rest, [codeblock, type], context, _loc, _bytes) do
    {rest, [%Block{type: type, code: codeblock}], context}
  end

  def block(rest, [{:clobbers, clobbers}, codeblock, type], context, _loc, _bytes) do
    {rest, [%Block{type: type, code: codeblock, clobbers: clobbers}], context}
  end

  defmodule Loop do
    # A labeled block of code that loops forever. The body must be `noreturn`: loops
    # occur through an explicit `repeat` instruction pointing back to this one.
    # Result type is always `noreturn`; no instructions in a block follow this one.
    # There is always at least one `repeat` instruction referencing the loop.
    # Uses the `ty_pl` field. Payload is `Block`.

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

  def loop(rest, [codeblock, type], context, _loc, _bytes) do
    {rest, [%Loop{type: type, code: codeblock}], context}
  end

  defmodule Repeat do
    # Sends control flow back to the beginning of a parent `loop` body.
    # Uses the `repeat` field.
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

  def repeat(rest, [goto], context, _loc, _bytes) do
    {rest, [%Repeat{goto: goto}], context}
  end

  defmodule Br do
    # Return from a block with a result.
    # Result type is always noreturn; no instructions in a block follow this one.
    # Uses the `br` field.
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

  defmodule CondBr do
    # Conditional branch.
    # Result type is always noreturn; no instructions in a block follow this one.
    # Uses the `pl_op` field. Operand is the condition. Payload is `CondBr`.

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
    cond_br: [post_traverse: :cond_br],
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
    # Switch branch.
    # Result type is always noreturn; no instructions in a block follow this one.
    # Uses the `pl_op` field. Operand is the condition. Payload is `SwitchBr`.

    defstruct [:test, :cases, :loop]
  end

  Pegasus.parser_from_string(
    """
    switch_br <- loop_prefix? switch_br_str lparen slotref (cs switch_case)* (cs else_case)? (newline space*)? rparen

    switch_case <- lbrack case_value (cs case_value)* rbrack (space modifier)? space fatarrow space codeblock_clobbers 
    case_value <- range / literal / lvalue
    else_case <- else (space modifier)? space fatarrow space codeblock_clobbers

    range <- (literal / lvalue) elision (literal / lvalue)

    modifier <- switch_cold / switch_unlikely

    loop_prefix <- 'loop_'

    switch_br_str <- 'switch_br'
    else <- 'else'

    switch_unlikely <- '.unlikely'
    switch_cold <- '.cold'
    """,
    loop_prefix: [token: :loop],
    switch_br: [post_traverse: :switch_br],
    switch_br_str: [ignore: true],
    else: [token: :else],
    switch_case: [post_traverse: :switch_case],
    else_case: [post_traverse: :else_case],
    switch_cold: [token: :cold],
    switch_unlikely: [token: :unlikely]
  )

  defp switch_br(rest, args, context, _loc, _bytes) do
    case Enum.reverse(args) do
      [:loop, test | cases] ->
        {rest, [%SwitchBr{test: test, cases: Map.new(cases), loop: true}], context}

      [test | cases] ->
        {rest, [%SwitchBr{test: test, cases: Map.new(cases), loop: false}], context}
    end
  end

  @modifiers ~w[cold unlikely]a

  defp switch_case(rest, [codeblock, modifier | compares], context, _loc, _bytes)
       when modifier in @modifiers do
    {rest, [{compares, codeblock}], context}
  end

  defp switch_case(rest, [codeblock, rhs, :..., lhs], context, _loc, _bytes) do
    {rest, [{{:range, lhs, rhs}, codeblock}], context}
  end

  defp switch_case(rest, [codeblock | compares], context, _loc, _bytes) do
    {rest, [{compares, codeblock}], context}
  end

  defp else_case(rest, [codeblock, modifier, :else], context, _loc, _bytes)
       when modifier in @modifiers do
    {rest, [{:else, codeblock}], context}
  end

  defp else_case(rest, [codeblock, :else], context, _loc, _bytes) do
    {rest, [{:else, codeblock}], context}
  end

  defmodule SwitchDispatch do
    # Dispatches back to a branch of a parent `loop_switch_br`.
    # Result type is always noreturn; no instructions in a block follow this one.
    # Uses the `br` field. `block_inst` is a `loop_switch_br` instruction.

    defstruct [:fwd, :goto]
  end

  Pegasus.parser_from_string(
    """
    switch_dispatch <- switch_dispatch_str lparen slotref cs argument rparen
    switch_dispatch_str <- 'switch_dispatch' 
    """,
    switch_dispatch: [post_traverse: :switch_dispatch],
    switch_dispatch_str: [ignore: true]
  )

  def switch_dispatch(rest, [fwd, goto], context, _loc, _bytes) do
    {rest, [%SwitchDispatch{goto: goto, fwd: fwd}], context}
  end

  defmodule Try do
    # Given an operand which is an error union, splits control flow. In
    # case of error, control flow goes into the block that is part of this
    # instruction, which is guaranteed to end with a return instruction
    # and never breaks out of the block.
    # In the case of non-error, control flow proceeds to the next instruction
    # after the `try`, with the result of this instruction being the unwrapped
    # payload value, as if `unwrap_errunion_payload` was executed on the operand.
    # The error branch is considered to have a branch hint of `.unlikely`.
    # Uses the `pl_op` field. Payload is `Try`.

    defstruct [:src, :error_code, clobbers: [], ptr: false, cold: false]

    use Clr.Air.Instruction
    alias Clr.Block

    def slot_type(%{src: {src, _}}, block) do
      {{:errorunion, _, payload, _}, block} = Block.fetch_up!(block, src)
      {payload, block}
    end

    def analyze(%{src: {src, _}}, slot, block, _config) do
      {{:errorunion, _, payload, _meta}, block} = Block.fetch_up!(block, src)
      # for now.  Ultimately, we will need to walk the analysis on this, too.
      {:halt, Block.put_type(block, slot, payload)}
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

  defp try(rest, [{:clobbers, clobbers}, error_code, src | maybe_cold], context, _loc, _bytes) do
    {rest, [%Try{src: src, error_code: error_code, clobbers: clobbers, cold: cold?(maybe_cold)}],
     context}
  end

  defp cold?([:cold]), do: true
  defp cold?([]), do: false

  defmodule TryPtr do
    # Same as `try` except the operand is a pointer to an error union, and the
    # result is a pointer to the payload. Result is as if `unwrap_errunion_payload_ptr`
    # was executed on the operand.
    # Uses the `ty_pl` field. Payload is `TryPtr`.

    defstruct [:src, :type, :error_code, clobbers: [], cold: false]

    use Clr.Air.Instruction
    alias Clr.Block

    def slot_type(%{src: {src, _}}, block) do
      {{:ptr, :one, {:errorunion, _, payload, _}, ptr_meta}, block} =
        Block.fetch_up!(block, src)

      {{:ptr, :one, payload, ptr_meta}, block}
    end
  end

  Pegasus.parser_from_string(
    """
    # NB: cold_mod is in the previous parser

    try_ptr <- try_ptr_str cold_mod? lparen slotref cs type cs codeblock_clobbers (space clobbers)? rparen

    try_ptr_str <- 'try_ptr'
    """,
    try_ptr: [post_traverse: :try_ptr],
    try_ptr_str: [ignore: true]
  )

  defp try_ptr(
         rest,
         [{:clobbers, clobbers}, error_code, type, src | maybe_cold],
         context,
         _slot,
         _bytes
       ) do
    {rest,
     [
       %TryPtr{
         src: src,
         error_code: error_code,
         clobbers: clobbers,
         type: type,
         cold: cold?(maybe_cold)
       }
     ], context}
  end

  # Indicates the program counter will never get to this instruction.
  # Result type is always noreturn; no instructions in a block follow this one.
  Air.noreturn(:unreach, Unreach)
end
