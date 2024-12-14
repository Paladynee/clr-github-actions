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
    other_literal <- langle type cs convertible rangle
    convertible <- as / name
    as <- '@as' lparen ptr_type cs value rparen
    value <- ptrcast / name
    ptrcast <- '@ptrCast' lparen name rparen

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
    # literal toolbox
    as: [post_traverse: :as],
    ptrcast: [post_traverse: :ptrcast],
    type: [export: true, parser: true, post_traverse: :type],
    typelist: [export: true],
    ptr_type: [post_traverse: :ptr_type],
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

  defp as(rest, [value, type, "@as"], context, _line, _bytes) do
    {rest, [{:as, type, value}], context}
  end

  defp ptrcast(rest, [name, "@ptrCast"], context, _line, _bytes) do
    {rest, [{:ptrcast, name}], context}
  end

  # TYPE post-traversals

  defp type(rest, [type], context, _line, _bytes), do: {rest, [type], context}

  defp type(rest, [{:ptr, kind, type}, "?"], context, _line, _bytes) do
    {rest, [{:ptr, kind, type, optional: true}], context}
  end

  defp type(rest, [{:ptr, kind, type, opts}, "?"], context, _line, _bytes) do
    {rest, [{:ptr, kind, type, Keyword.put(opts, :optional, true)}], context}
  end

  defp type(rest, [type, "?"], context, _line, _bytes) do
    {rest, [{:optional, type}], context}
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

  defp ptr_type(rest, args, context, _, _) do
    {rest, [ptrfor(args)], context}
  end

  defp ptrfor([type, "*"]), do: {:ptr, :one, type}
  defp ptrfor([type, "[*]"]), do: {:ptr, :many, type}
  defp ptrfor([type, "[]"]), do: {:ptr, :slice, type}

  defp ptrfor([type, "]", sentinel, "[*:"]) do
    {:ptr, :many, type, sentinel: sentinel}
  end

  defp ptrfor([type, "]", sentinel, "[:"]) do
    {:ptr, :slice, type, sentinel: sentinel}
  end

  defp ptrfor([type, :const | qualifiers]) do
    case ptrfor([type | qualifiers]) do
      {:ptr, kind, name} -> {:ptr, kind, name, const: true}
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :const, true)}
    end
  end

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
