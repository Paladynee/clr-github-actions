defmodule Clr.Air.Parser do
  require Pegasus

  alias Clr.Air.Function
  alias Clr.Air.Instruction

  Pegasus.parser_from_string(
    """
    # initialization
    init <- ''
    air <- init function *

    name <- [0-9a-zA-Z._@] +
    function <- function_head function_meta* code function_foot
    function_head <- '# Begin Function AIR:' space name ':' newline
    function_foot <- '# End Function AIR:' space name newline?
    function_meta <- function_meta_title space+ function_meta_info newline
    function_meta_title <- '# Total AIR+Liveness bytes:' / 
      '# AIR Instructions:' / 
      '# AIR Extra Data:' / 
      '# Liveness tomb_bits:' / 
      '# Liveness Extra Data:' / 
      '# Liveness special table:'
    function_meta_info <- [^\n]+

    int <- [0-9]+

    lineref <- clobber / lineno
    lineno <- '%' int
    clobber <- '%' int '!'

    code <- codeline+
    codeline <- space* ((lineref (space)? '=' space instruction) / clobbers) newline
    clobbers <- clobber (space clobber)*

    tag <- '.@' ["] [^"]+ ["]

    instruction <- dbg_stmt / dbg_inline_block / dbg_arg_inline / dbg_var_val / dbg_var_ptr / dbg_empty_stmt / br / assembly / trap / 
                   arg / ptr_elem_val / ptr_add / bitcast / alloc / store / block / loop / load / is_non_null / cond_br /
                   optional_payload / add / repeat / slice / slice_ptr / struct_field_val / cmp_neq / switch_br / 
                   call / unknown_instruction

    dbg_stmt <- 'dbg_stmt(' intrange ')'
    dbg_inline_block <- 'dbg_inline_block(' name cs fun cs codeblock ')'
    dbg_arg_inline <- 'dbg_arg_inline(' langle name cs name rangle cs dquoted ')'
    dbg_var_val <- 'dbg_var_val(' lineref cs dquoted ')'
    dbg_var_ptr <- 'dbg_var_ptr(' lineref cs dquoted ')'
    dbg_empty_stmt <- 'dbg_empty_stmt()'
    br <- 'br(' lineref cs (name / lineref) ')'
    assembly <- 'assembly(' name cs name cs asm_in cs asm_in cs dstring ')'
    trap <- 'trap('')'
    arg <- 'arg(' type cs dquoted ')'
    ptr_elem_val <- 'ptr_elem_val(' lineref cs (lineref / name) ')'
    ptr_add <- 'ptr_add(' type cs lineref cs (lineref / name) ')'
    bitcast <- 'bitcast(' type cs lineref ')'
    alloc <- 'alloc(' type ')'
    store <- 'store(' (lineref / literal) cs (lineref / name) ')'
    block <- 'block(' type cs codeblock (space clobbers)? ')'
    loop <- 'loop(' type cs codeblock ')'
    load <- 'load(' type cs lineref ')'
    is_non_null <- 'is_non_null(' lineref ')'
    cond_br <- 'cond_br(' lineref cs cond_modifier space codeblock cs cond_modifier space codeblock notnewline # ')'
    optional_payload <- 'optional_payload(' type cs lineref ')'
    add <- 'add(' lineref cs (lineref / name) ')'
    repeat <- 'repeat(' lineref ')'
    slice <- 'slice(' type cs lineref cs lineref ')'
    slice_ptr <- 'slice_ptr(' type cs lineref ')'
    struct_field_val <- 'struct_field_val(' lineref cs int ')'
    cmp_neq <- 'cmp_neq(' lineref cs int_literal ')'
    switch_br <- 'switch_br(' lineref (cs switch_case)* (cs else_case)? (newline space*)? ')'
    call <- 'call(' fn_literal cs lbrack (lineref (cs lineref)*)? rbrack')'

    cond_modifier <- 'poi' / 'likely' / 'cold'

    # an "in" statement for assembly language
    asm_in <- lbrack name rbrack space 'in' space name space '=' space lparen asmfun rparen

    # for debugging
    notnewline <- [^\n]*
    unknown_instruction <- name lparen notnewline

    switch_case <- lbrack int_literal (cs int_literal)* rbrack space arrow space codeblock 
    else_case <- 'else' space arrow space codeblock

    intrange <- int colon int
    literal <- int_literal / other_literal
    int_literal <- langle type cs int rangle
    fn_literal <- langle fn_type cs lparen 'function' space quoted rparen rangle
    other_literal <- langle type cs name rangle

    # TODO: build this back into "fn_literal" and type literals.

    fun <- langle 'fn' space lparen name (cs name)* rparen space 'callconv' lparen tag rparen space name cs lparen 'function' space quoted rparen rangle
    asmfun <- langle ('*const' space)? 'fn' space typelist space 'callconv' lparen name rparen space name cs name rangle

    typelist <- lparen type* rparen
    type <- '?'? (name / ptr_type)
    ptr_type <- ('[*]' / '[*:' name ']' / '[]' / '*') ('const' space)? type
    fn_type <- 'fn' space lparen type (cs type)* rparen space type

    codeblock <- lbrace newline codeline+ space* rbrace

    quoted <- singleq name singleq
    dquoted <- doubleq name doubleq
    dstring <- doubleq [^"]* doubleq

    cs <- comma space

    # single token categories

    singleq <- [']
    doubleq <- ["]
    comma <- ','
    space <- '\s'
    colon <- ':'
    lparen <- '('
    rparen <- ')'
    langle <- '<'
    rangle <- '>'
    lbrace <- '{'
    rbrace <- '}'
    lbrack <- '['
    rbrack <- ']'
    arrow <- '=>'
    newline <- '\s'* '\n'
    """,
    air: [parser: true],
    init: [post_traverse: :init],
    function: [post_traverse: :function],
    function_head: [post_traverse: :function_head],
    function_meta: [ignore: true],
    function_foot: [post_traverse: :function_foot],
    codeline: [post_traverse: :codeline],
    fun: [post_traverse: :fun],
    clobber: [post_traverse: :clobber],
    lineno: [post_traverse: :lineno],
    lineno: [collect: true],
    content: [collect: true],
    name: [collect: true],
    tag: [collect: true],
    dstring: [collect: true],
    space: [ignore: true],
    comma: [ignore: true],
    colon: [ignore: true],
    langle: [ignore: true],
    rangle: [ignore: true],
    lparen: [ignore: true],
    rparen: [ignore: true],
    lbrace: [ignore: true],
    rbrace: [ignore: true],
    lbrack: [ignore: true],
    rbrack: [ignore: true],
    newline: [ignore: true],
    singleq: [ignore: true],
    doubleq: [ignore: true],
    arrow: [ignore: true],
    notnewline: [collect: true],
    type: [post_traverse: :type],
    fn_type: [post_traverse: :fn_type],
    int: [collect: true, post_traverse: :int],
    int_literal: [post_traverse: :literal],
    other_literal: [post_traverse: :literal],
    fn_literal: [post_traverse: :literal],
    intrange: [post_traverse: :intrange],
    asm_in: [post_traverse: :asm_in],
    asmfun: [post_traverse: :asmfun],
    dbg_stmt: [post_traverse: {:instruction, [:dbg_stmt]}],
    dbg_inline_block: [post_traverse: {:instruction, [:dbg_inline_block]}],
    dbg_arg_inline: [post_traverse: {:instruction, [:dbg_arg_inline]}],
    dbg_var_val: [post_traverse: {:instruction, [:dbg_var_val]}],
    dbg_var_ptr: [post_traverse: {:instruction, [:dbg_var_ptr]}],
    dbg_empty_stmt: [post_traverse: {:instruction, [:dbg_empty_stmt]}],
    br: [post_traverse: {:instruction, [:br]}],
    assembly: [post_traverse: {:instruction, [:assembly]}],
    trap: [post_traverse: {:instruction, [:trap]}],
    arg: [post_traverse: {:instruction, [:arg]}],
    ptr_elem_val: [post_traverse: {:instruction, [:ptr_elem_val]}],
    ptr_add: [post_traverse: {:instruction, [:ptr_add]}],
    bitcast: [post_traverse: {:instruction, [:bitcast]}],
    alloc: [post_traverse: {:instruction, [:alloc]}],
    store: [post_traverse: {:instruction, [:store]}],
    block: [post_traverse: {:instruction, [:block]}],
    loop: [post_traverse: {:instruction, [:loop]}],
    load: [post_traverse: {:instruction, [:load]}],
    is_non_null: [post_traverse: {:instruction, [:is_non_null]}],
    cond_br: [post_traverse: {:instruction, [:cond_br]}],
    add: [post_traverse: {:instruction, [:add]}],
    optional_payload: [post_traverse: {:instruction, [:optional_payload]}],
    repeat: [post_traverse: {:instruction, [:repeat]}],
    slice: [post_traverse: {:instruction, [:slice]}],
    slice_ptr: [post_traverse: {:instruction, [:slice_ptr]}],
    struct_field_val: [post_traverse: {:instruction, [:struct_field_val]}],
    switch_br: [post_traverse: {:instruction, [:switch_br]}],
    cmp_neq: [post_traverse: {:instruction, [:cmp_neq]}],
    call: [post_traverse: {:instruction, [:call]}],
    unknown_instruction: [post_traverse: :unknown_instruction]
  )

  defp init(rest, _, _context, _line, _bytes) do
    {rest, [], %Function{}}
  end

  defp int(rest, [value], context, _line, _bytes) do
    {rest, [String.to_integer(value)], context}
  end

  defp lineno(rest, [line, "%"], context, _line, _bytes) do
    {rest, [{line, :keep}], context}
  end

  defp clobber(rest, ["!", line, "%"], context, _line, _bytes) do
    {rest, [{line, :clobber}], context}
  end

  defp function_head(rest, [_, name, _], context, _line, _bytes) do
    {rest, [], %{context | name: name}}
  end

  defp function_foot(rest, [name, _], %{name: expected_name} = context, _line, _bytes) do
    if expected_name != name do
      raise "function foot name #{name} mismatches expected name #{expected_name}"
    end

    {rest, [], context}
  end

  defp codeline(rest, [instruction, "=", codeline], context, _line, _bytes) do
    {rest, [{codeline, instruction}], context}
  end

  defp codeline(rest, clobbers, context, _line, _bytes) do
    {rest, [{:clobbers, Enum.map(clobbers, &elem(&1, 0))}], context}
  end

  defp intrange(rest, [left, right], context, _line, _bytes) do
    {rest, [{left, right}], context}
  end

  defp literal(rest, [value, type], context, _line, _bytes) do
    {rest, [{type, value}], context}
  end

  defp literal(rest, [name, "function", type], context, _line, _bytes) do
    {rest, [{type, {:function, name}}], context}
  end

  defp function(rest, args, context, _line, _bytes) do
    {rest, [], %{context | code: Instruction.to_code(args)}}
  end

  defp instruction(rest, args, context, _line, _bytes, function) do
    decoded = args |> Enum.slice(1..-2//1) |> Enum.reverse() |> Instruction.initialize(function)
    {rest, [decoded], context}
  end

  defp fun(rest, [call, "function", type, _, "callconv" | rargs], context, _line, _bytes) do
    {rest, [{:function, call, type, Enum.reverse(rargs)}], context}
  end

  def parse(string) do
    case air(string) do
      {:ok, [], "", parser, _, _} -> parser
    end
  end

  defp asmfun(rest, [name, return_type, callconv, "callconv" | args_rest], context, _line, _bytes) do
    fun =
      case Enum.reverse(args_rest) do
        ["*const", "fn" | param_types] ->
          {:constptr, :fun, name, return_type, callconv, param_types}
      end

    {rest, [fun], context}
  end

  defp asm_in(rest, [fndef, "=", "X", "in", name], context, _line, _bytes) do
    {rest, [{:asm_in, name, fndef}], context}
  end

  defp type(rest, typeargs, context, _line, _bytes) do
    {rest, [typefor(typeargs)], context}
  end

  defp fn_type(rest, [return_type | rest_args], context, _line, _bytes) do
    ["fn" | arg_types] = Enum.reverse(rest_args)
    {rest, [{:fn, arg_types, return_type}], context}
  end

  defp typefor([name]), do: name

  defp typefor([name, "const" | rest]) do
    case typefor([name | rest]) do
      {:ptr, kind, name} -> {:ptr, kind, name, const: true}
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :const, true)}
    end
  end

  defp typefor([name, "?" | rest]), do: typefor([{:optional, name} | rest])
  defp typefor([name, "*" | rest]), do: typefor([{:ptr, :one, name} | rest])
  defp typefor([name, "[*]" | rest]), do: typefor([{:ptr, :many, name} | rest])
  defp typefor([name, "[]" | rest]), do: typefor([{:ptr, :slice, name} | rest])

  defp typefor([name, "]", value, "[*:" | rest]),
    do: typefor([{:ptr, :many, name, sentinel: value} | rest])

  defp unknown_instruction(_rest, [rest, instruction], _context, {line, _}, _bytes) do
    raise "unknown instruction \"#{instruction}(#{rest}\" found on line #{line}"
  end
end
