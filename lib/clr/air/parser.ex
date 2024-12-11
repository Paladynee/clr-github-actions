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

    lineref <- '%' lineno '!'?
    code <- codeline+
    codeline <- space* '%' lineno iso '=' space instruction newline
    lineno <- [0-9]+
    iso <- '!' / space

    tag <- '.@' ["] [^"]+ ["]
    tag2 <- name

    instruction <- dbg_stmt / dbg_inline_block / dbg_arg_inline / dbg_var_val / dbg_var_ptr / br / assembly / trap / arg / 
                   ptr_elem_val / ptr_add / bitcast / alloc / store / unknown_instruction
    dbg_stmt <- 'dbg_stmt(' intrange ')'
    dbg_inline_block <- 'dbg_inline_block(' name comma space fun comma space block rparen
    dbg_arg_inline <- 'dbg_arg_inline(' langle name comma space name rangle comma space dquoted ')'
    dbg_var_val <- 'dbg_var_val(' lineref comma space dquoted ')'
    dbg_var_ptr <- 'dbg_var_ptr(' lineref comma space dquoted ')'
    br <- 'br(' lineref comma space name ')'
    assembly <- 'assembly(' name comma space name comma space asm_in comma space asm_in comma space dstring ')'
    trap <- 'trap('')'
    arg <- 'arg(' type comma space dquoted ')'
    ptr_elem_val <- 'ptr_elem_val(' lineref comma space tag2 ')'
    ptr_add <- 'ptr_add(' type comma space lineref comma space (lineref / tag2) ')'
    bitcast <- 'bitcast(' type comma space lineref ')'
    alloc <- 'alloc(' type ')'
    store <- 'store(' lineref comma space tag2 ')'

    # an "in" statement for assembly language
    asm_in <- lbrack name rbrack space 'in' space name space '=' space lparen asmfun rparen

    # for debugging
    notnewline <- [^\n]*
    unknown_instruction <- name lparen notnewline

    int <- [0-9]+
    intrange <- int colon int
    fun <- langle 'fn' space lparen name (comma space name)* rparen space 'callconv' lparen tag rparen space name comma space lparen 'function' space quoted rparen rangle
    asmfun <- langle ('*const' space)? 'fn' space typelist space 'callconv' lparen tag2 rparen space name comma space name rangle

    typelist <- lparen type* rparen
    type <- '?'? (name / ptr_type)
    ptr_type <- ('[*]' / '[*:' name ']' / "*") type

    block <- lbrace newline codeline+ space* rbrace

    quoted <- singleq name singleq
    dquoted <- doubleq name doubleq
    dstring <- doubleq [^"]* doubleq

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
    lineref: [post_traverse: :lineref],
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
    notnewline: [collect: true],
    type: [post_traverse: :type],
    int: [collect: true],
    intrange: [post_traverse: :intrange],
    asm_in: [post_traverse: :asm_in],
    asmfun: [post_traverse: :asmfun],
    dbg_stmt: [post_traverse: {:instruction, [:dbg_stmt]}],
    dbg_inline_block: [post_traverse: {:instruction, [:dbg_inline_block]}],
    dbg_arg_inline: [post_traverse: {:instruction, [:dbg_arg_inline]}],
    dbg_var_val: [post_traverse: {:instruction, [:dbg_var_val]}],
    dbg_var_ptr: [post_traverse: {:instruction, [:dbg_var_ptr]}],
    br: [post_traverse: {:instruction, [:br]}],
    assembly: [post_traverse: {:instruction, [:assembly]}],
    trap: [post_traverse: {:instruction, [:trap]}],
    arg: [post_traverse: {:instruction, [:arg]}],
    ptr_elem_val: [post_traverse: {:instruction, [:ptr_elem_val]}],
    ptr_add: [post_traverse: {:instruction, [:ptr_add]}],
    bitcast: [post_traverse: {:instruction, [:bitcast]}],
    alloc: [post_traverse: {:instruction, [:alloc]}],
    store: [post_traverse: {:instruction, [:store]}],
    unknown_instruction: [post_traverse: :unknown_instruction]
  )

  defp init(rest, _, _context, _line, _bytes) do
    {rest, [], %Function{}}
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

  defp codeline(rest, [code, "=", "!", no, "%"], context, _line, _bytes) do
    {rest, [{String.to_integer(no), true, code}], context}
  end

  defp codeline(rest, [code, "=", no, "%"], context, _line, _bytes) do
    {rest, [String.to_integer(no), false, code], context}
  end

  defp intrange(rest, [left, right], context, _line, _bytes) do
    {rest, [{String.to_integer(left), String.to_integer(right)}], context}
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

  defp lineref(rest, ["!", line, "%"], context, _line, _bytes) do
    {rest, [{:unused, String.to_integer(line)}], context}
  end

  defp lineref(rest, [line, "%"], context, _line, _bytes) do
    {rest, [String.to_integer(line)], context}
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

  defp typefor([name]), do: name
  defp typefor([name, "?" | rest]), do: typefor([{:optional, name} | rest])
  defp typefor([name, "*" | rest]), do: typefor([{:ptr, :one, name} | rest])
  defp typefor([name, "[*]" | rest]), do: typefor([{:ptr, :many, name} | rest])
  defp typefor([name, "]", value, "[*:" | rest]), do: typefor([{:ptr, :many, name, sentinel: value} | rest])

  defp unknown_instruction(_rest, [rest, instruction], _context, _line, _bytes) do
    raise "unknown instruction #{instruction}(#{rest} found"
  end
end
