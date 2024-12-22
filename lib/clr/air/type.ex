defmodule Clr.Air.Type do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[int identifier enum_literal squoted space dot comma cs lparen rparen langle rangle lbrack rbrack lbrace rbrace dstring notnewline]a
  )

  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue basic_lvalue]a)

  Pegasus.parser_from_string(
    """
    # full type things
    type <- (comptime space)? typedecl
    typedecl <- errorable_types / general_types
    errorable_types <- error_prefix bang general_types
    error_prefix <- anyerror / errorunion / lvalue

    general_types <- '?'? (errorunion / enum_literal_type / fn_type / ptr_type / array_type / struct_type / lvalue)

    # special types
    enum_literal_type <- '@Type(.enum_literal)'

    ptr_type <- (one_ptr / many_ptr / slice_ptr / sentinel_many_ptr / sentinel_slice_ptr) (allowzero space)? (volatile space)? (alignment space)? (const space)? type
    array_type <- '[' int (':' int)? ']' type

    one_ptr <- '*'
    many_ptr <- '[*]'
    slice_ptr <- '[]'
    sentinel_many_ptr <- '[*:' sentinel ']'
    sentinel_slice_ptr <- '[:' sentinel ']'
    alignment <- align lparen int rparen

    sentinel <- 'null' / '0'

    fn_type <- ('*' const space)? 'fn' space typelist (space callconv)? space type
    typelist <- lparen ((noalias space)? type (cs (noalias space)? type)*)? rparen

    callconv <- 'callconv' lparen (inline / c / naked) rparen
    inline <- '.@"inline"'
    c <- '.c'
    naked <- '.naked'

    struct_type <- 'struct' space lbrace space type (cs type)* space rbrace

    errorunion <- 'anyerror' / error errorlist
    errorlist <- lbrace (identifier (comma identifier)*)? rbrace

    ## single token words
    allowzero <- 'allowzero'
    volatile <- 'volatile'
    const <- 'const'
    comptime <- 'comptime'
    align <- 'align'
    noalias <- 'noalias'
    error <- 'error'
    anyerror <- 'anyerror'
    bang <- '!'
    """,
    type: [export: true, parser: true, post_traverse: :type],
    errorable_types: [post_traverse: :errorable_types],
    general_types: [post_traverse: :general_types],
    enum_literal_type: [token: :enum_literal],
    comptime_call_type: [export: true, post_traverse: :comptime_call_type],
    comptime_call_params: [post_traverse: :comptime_call_params],
    ptr_type: [export: true, post_traverse: :ptr_type],
    array_type: [post_traverse: :array_type],
    fn_type: [export: true, post_traverse: :fn_type],
    sentinel: [collect: true, post_traverse: :sentinel],
    callconv: [post_traverse: :callconv],
    inline: [token: :inline],
    c: [token: :c],
    naked: [token: :naked],
    function: [token: :function],
    map_value: [collect: true],
    struct_type: [post_traverse: :struct_type],
    stringliteral: [post_traverse: :stringliteral],
    errorunion_only: [post_traverse: :errorunion_only],
    errorlist: [post_traverse: :errorlist],
    structptr: [post_traverse: :structptr],
    sizeof: [post_traverse: :sizeof],
    alignof: [post_traverse: :alignof],
    builtinfunction: [post_traverse: :builtinfunction],
    allowzero: [token: :allowzero],
    volatile: [token: :volatile],
    const: [token: :const],
    comptime: [token: :comptime],
    align: [token: :align],
    noalias: [token: :noalias],
    error: [token: :error],
    anyerror: [token: :anyerror],
    bang: [token: :!]
  )

  # TYPE post-traversals

  defp type(rest, [type], context, _line, _bytes), do: {rest, [type], context}

  defp type(rest, [type, :comptime], context, _line, _bytes) do
    {rest, [comptime: type], context}
  end

  defp errorable_types(rest, [payload, :!, :anyerror], context, _line, _bytes) do
    {rest, [{:errorable, :any, payload}], context}
  end

  defp errorable_types(rest, [payload, :!, errortype], context, _line, _bytes) do
    {rest, [{:errorable, errortype, payload}], context}
  end

  defp errorable_types(rest, [payload, :!, errorset, :error], context, _line, _bytes) do
    {rest, [{:errorable, errorset, payload}], context}
  end

  defp general_types(rest, [errorset, :error], context, _line, _bytes) do
    {rest, [{:errorset, errorset}], context}
  end

  defp general_types(rest, [{:ptr, kind, type, opts}, "?"], context, _line, _bytes) do
    {rest, [{:ptr, kind, type, Keyword.put(opts, :optional, true)}], context}
  end

  defp general_types(rest, [type, "?"], context, _line, _bytes) do
    {rest, [{:optional, type}], context}
  end

  defp general_types(rest, [type], context, _line, _bytes) do
    {rest, [type], context}
  end

  defp array_type(rest, [type, "]", sentinel, ":", int, "["], context, _line, _bytes) do
    {rest, [{:array, int, type, [sentinel: sentinel]}], context}
  end

  defp array_type(rest, [type, "]", int, "["], context, _line, _bytes) do
    {rest, [{:array, int, type, []}], context}
  end

  defp fn_type(rest, [return_type | args_rest], context, _line, _bytes) do
    {arg_types, opts} = fn_info(args_rest, [])
    {rest, [{:fn, arg_types, return_type, opts}], context}
  end

  defp fn_info([{:callconv, _} = callconv | rest], opts), do: fn_info(rest, [callconv | opts])
  defp fn_info(rest, opts), do: {fn_args(rest), opts}

  defp fn_args(args) do
    case Enum.reverse(args) do
      ["fn" | args] -> collect_noalias(args, [])
      ["*", :const, "fn" | args] -> collect_noalias(args, [])
    end
  end

  defp collect_noalias([:noalias, type | rest], so_far) do
    collect_noalias(rest, [{:noalias, type} | so_far])
  end

  defp collect_noalias([head | rest], so_far), do: collect_noalias(rest, [head | so_far])

  defp collect_noalias([], so_far), do: Enum.reverse(so_far)

  defp ptr_type(rest, args, context, _, _) do
    {rest, [ptrfor(args)], context}
  end

  defp ptrfor([type, "*"]), do: {:ptr, :one, type, []}
  defp ptrfor([type, "[*]"]), do: {:ptr, :many, type, []}
  defp ptrfor([type, "[]"]), do: {:ptr, :slice, type, []}

  defp ptrfor([type, "]", sentinel, "[*:"]) do
    {:ptr, :many, type, sentinel: sentinel}
  end

  defp ptrfor([type, "]", sentinel, "[:"]) do
    {:ptr, :slice, type, sentinel: sentinel}
  end

  defp ptrfor([type, alignment, :align | rest]) do
    case ptrfor([type | rest]) do
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :alignment, alignment)}
    end
  end

  defp ptrfor([type, :const | qualifiers]) do
    case ptrfor([type | qualifiers]) do
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :const, true)}
    end
  end

  defp ptrfor([type, :volatile | qualifiers]) do
    case ptrfor([type | qualifiers]) do
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :volatile, true)}
    end
  end

  defp ptrfor([type, :allowzero | qualifiers]) do
    case ptrfor([type | qualifiers]) do
      {:ptr, kind, name, opts} -> {:ptr, kind, name, Keyword.put(opts, :allowzero, true)}
    end
  end

  defp sentinel(rest, ["null"], context, _line, _bytes) do
    {rest, [:null], context}
  end

  defp sentinel(rest, ["0"], context, _line, _bytes) do
    {rest, [0], context}
  end

  defp struct_type(rest, args, context, _line, _bytes) do
    case Enum.reverse(args) do
      ["struct" | types] -> {rest, [{:struct, types}], context}
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

  defp errorlist(rest, errors, context, _line, _bytes) do
    {rest, [errors], context}
  end
end
