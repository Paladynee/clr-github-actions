defmodule Clr.Air.Type do
  require Pegasus

  Pegasus.parser_from_string(
    """
    type <- '?'? (name / ptr_type)
    ptr_type <- (one_ptr / many_ptr / slice_ptr / sentinel_many_ptr / sentinel_slice_ptr) ('const' space)? type

    one_ptr <- '*'
    many_ptr <- '[*]'
    slice_ptr <- '[]'
    sentinel_many_ptr <- '[*:' name ']'
    sentinel_slice_ptr <- '[:' name ']'

    fn_type <- 'fn' space lparen type (cs type)* rparen space type

    # TODO: consolidate these

    name <- [0-9a-zA-Z._@] +

    # TODO: consolidate these

    cs <- comma space

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
    type: [parser: true, post_traverse: :type],
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
    fn_type: [post_traverse: :fn_type]
  )

  defp fn_type(_, _, _, _, _) do
    raise "fn_type not implemented"
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
  defp typefor([name, "]", value, "[:" | rest]),
    do: typefor([{:ptr, :slice, name, sentinel: value} | rest])

  def parse(str) do
    case type(str) do
      {:ok, result, "", _context, _line, _bytes} -> result
    end
  end
end
