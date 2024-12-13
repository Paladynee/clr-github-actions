defmodule Clr.Air.Type do
  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[int name quoted space comma cs lparen rparen langle rangle]a)

  Pegasus.parser_from_string(
    """
    # literals are type + value
    literal <- int_literal / fn_literal / other_literal
    int_literal <- langle type cs int rangle
    fn_literal <- langle fn_type cs lparen 'function' space quoted rparen rangle
    other_literal <- langle type cs name rangle

    # full type things
    typelist <- lparen type (cs type)* rparen
    type <- '?'? (name / ptr_type / fn_type)
    ptr_type <- (one_ptr / many_ptr / slice_ptr / sentinel_many_ptr / sentinel_slice_ptr) (const space)? type

    # single token words
    const <- 'const'
    function <- 'function'

    one_ptr <- '*'
    many_ptr <- '[*]'
    slice_ptr <- '[]'
    sentinel_many_ptr <- '[*:' name ']'
    sentinel_slice_ptr <- '[:' name ']'

    fn_type <- 'fn' space typelist space type
    """,
    literal: [export: true, post_traverse: :literal],
    type: [parser: true, export: true, post_traverse: :type],
    typelist: [export: true],
    fn_type: [export: true, post_traverse: :fn_type],
    const: [token: :const],
    function: [token: :function]
  )

  defp codeline(rest, clobbers, context, _line, _bytes) do
    {rest, [{:clobbers, Enum.map(clobbers, &elem(&1, 0))}], context}
  end

  defp literal(rest, [value, type], context, _line, _bytes) do
    {rest, [{:literal, type, value}], context}
  end

  defp literal(rest, [name, :function, type], context, _line, _bytes) do
    {rest, [{:literal, type, {:function, name}}], context}
  end

  # TYPE post-traversals

  defp type(rest, typeargs, context, _line, _bytes) do
    {rest, [typefor(typeargs)], context}
  end

  defp fn_type(rest, [return_type | rest_args], context, _line, _bytes) do
    ["fn" | arg_types] = Enum.reverse(rest_args)
    {rest, [{:fn, arg_types, return_type}], context}
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

  def parse(str) do
    case type(str) do
      {:ok, result, "", _context, _line, _bytes} -> result
    end
  end
end
