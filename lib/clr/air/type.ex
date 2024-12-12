defmodule Clr.Air.Type do
  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[name space comma cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    type <- '?'? (name / ptr_type / fn_type)
    ptr_type <- (one_ptr / many_ptr / slice_ptr / sentinel_many_ptr / sentinel_slice_ptr) ('const' space)? type

    one_ptr <- '*'
    many_ptr <- '[*]'
    slice_ptr <- '[]'
    sentinel_many_ptr <- '[*:' name ']'
    sentinel_slice_ptr <- '[:' name ']'

    fn_type <- 'fn' space lparen type (cs type)* rparen space type
    """,
    type: [parser: true, post_traverse: :type],
    fn_type: [export: true, post_traverse: :fn_type]
  )

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
