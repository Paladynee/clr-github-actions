defmodule Clr.Air.Type do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[int name squoted space comma cs lparen rparen langle rangle notnewline]a
  )

  Pegasus.parser_from_string(
    """
    # literals are type + value
    literal <- int_literal / fn_literal / other_literal
    int_literal <- langle type cs int rangle
    fn_literal <- langle fn_type cs fn_value rangle
    fn_value <- (lparen function space squoted rparen) / name
    other_literal <- langle type cs name rangle

    # full type things
    typelist <- lparen (type (cs type)*)? rparen
    type <- '?'? (fn_type / ptr_type / name)
    ptr_type <- (one_ptr / many_ptr / slice_ptr / sentinel_many_ptr / sentinel_slice_ptr) (const space)? type

    # single token words
    const <- 'const'
    function <- 'function'

    one_ptr <- '*'
    many_ptr <- '[*]'
    slice_ptr <- '[]'
    sentinel_many_ptr <- '[*:' name ']'
    sentinel_slice_ptr <- '[:' name ']'

    fn_type <- ('*' const space)? 'fn' space typelist (space callconv)? space type
    callconv <- 'callconv' lparen (inline / c / naked) rparen
    inline <- '.@"inline"'
    c <- '.c'
    naked <- '.naked'
    function <- 'function'
    """,
    literal: [export: true, parser: true],
    int_literal: [export: true, post_traverse: :int_literal],
    fn_literal: [export: true, post_traverse: :fn_literal],
    other_literal: [export: true, post_traverse: :other_literal],
    type: [export: true, parser: true, post_traverse: :type],
    typelist: [export: true],
    fn_type: [export: true, post_traverse: :fn_type],
    const: [token: :const],
    function: [token: :function],
    callconv: [post_traverse: :callconv],
    inline: [token: :inline],
    c: [token: :c],
    naked: [token: :naked],
    function: [token: :function]
  )

  defp int_literal(rest, [value, type], context, _line, _bytes) when is_integer(value) do
    {rest, [{:literal, type, value}], context}
  end

  defp fn_literal(rest, [name, :function, type], context, _line, _bytes) do
    {rest, [{:literal, type, {:function, name}}], context}
  end

  defp fn_literal(rest, [name, type], context, _line, _bytes) do
    {rest, [{:literal, type, name}], context}
  end

  defp other_literal(rest, [value, type], context, _line, _bytes) do
    {rest, [{:literal, type, value}], context}
  end

  # TYPE post-traversals

  defp type(rest, typeargs, context, _line, _bytes) do
    {rest, [typefor(typeargs)], context}
  end

  defp fn_type(rest, [return_type | args_rest], context, _line, _bytes) do
    {arg_types, opts} = fn_info(args_rest, [])
    {rest, [{:fn, arg_types, return_type, opts}], context}
  end

  defp fn_info([{:callconv, _} = callconv | rest], opts), do: fn_info(rest, [callconv | opts])
  defp fn_info(rest, opts), do: {fn_args(rest), opts}

  defp fn_args(args) do
    case Enum.reverse(args) do
      ["fn" | args] -> args
      ["*", :const, "fn" | args] -> args
    end
  end

  defp typefor([name]), do: name

  defp typefor([name, :const | rest]) do
    case typefor([name | rest]) do
      {:ptr, kind, name} -> {:ptr, kind, name, const: true}
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :const, true)}
    end
  end

  # optional pointers get the optional modifiers
  defp typefor([{:ptr, count, name}, "?" | rest]),
    do: typefor([{:ptr, count, name, optional: true} | rest])

  defp typefor([{:ptr, count, name, opts}, "?" | rest]),
    do: typefor([{:ptr, count, name, Keyword.put(opts, :optional, true)} | rest])

  # optional anything else is a union
  defp typefor([name, "?" | rest]), do: typefor([{:optional, name} | rest])

  defp typefor([name, "*" | rest]), do: typefor([{:ptr, :one, name} | rest])
  defp typefor([name, "[*]" | rest]), do: typefor([{:ptr, :many, name} | rest])
  defp typefor([name, "[]" | rest]), do: typefor([{:ptr, :slice, name} | rest])

  defp typefor([name, "]", value, "[*:" | rest]),
    do: typefor([{:ptr, :many, name, sentinel: value} | rest])

  defp typefor([name, "]", value, "[:" | rest]),
    do: typefor([{:ptr, :slice, name, sentinel: value} | rest])

  # function post-traversals

  defp callconv(rest, [type, "callconv"], context, _line, _bytes) do
    {rest, [{:callconv, type}], context}
  end

  def parse(str) do
    case type(str) do
      {:ok, [result], "", _context, _line, _bytes} -> result
    end
  end

  def parse_literal(str) do
    case literal(str) do
      {:ok, [result], "", _context, _line, _bytes} -> result
    end
  end
end
