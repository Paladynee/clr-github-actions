defmodule Clr.Air.Literal do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[type lvalue comptime_struct fn_type ptr_type identifier int elision cs space dot lparen rparen langle rangle lbrack rbrack lbrace 
      rbrace squoted dstring]a
  )

  Pegasus.parser_from_string(
    """
    # literals are type + value
    literal <- fn_literal / enum_value / other_literal

    fn_literal <- langle fn_type cs lvalue rangle
    other_literal <- langle type cs convertible rangle

    # these are all of the things that are capable of being interpreted at comptime.
    # TODO: clean this up.
    convertible <- int / void / undefined / sizeof / alignof / as / string_value / struct_ptr / comptime_struct / enum_value / type

    string_value <- dstring (indices)?
    indices <- lbrack int '..' int rbrack

    # special builtin functions
    # TODO: move these into lvalue module.
    as <- '@as' lparen type cs (ptrcast / lvalue / int) rparen (dot "*")?
    ptrcast <- '@ptrCast' lparen (as / lvalue) rparen
    sizeof <- '@sizeOf' lparen type rparen
    alignof <- '@alignOf' lparen type rparen

    struct_ptr <- '&' comptime_struct range?

    range <- lbrack int '..' int rbrack

    undefined <- 'undefined'

    # does this belong here?
    enum_value <- dot identifier
    void <- '{}'

    # private
    eq <- "="
    """,
    literal: [parser: true, export: true],
    fn_literal: [export: true, post_traverse: :literal],
    other_literal: [export: true, post_traverse: :literal],
    string_value: [post_traverse: :string_value],
    convertible: [export: true],
    alignof: [post_traverse: :alignof],
    sizeof: [post_traverse: :sizeof],
    as: [post_traverse: :as],
    ptrcast: [post_traverse: :ptrcast],
    struct_ptr: [post_traverse: :struct_ptr],
    struct_value: [post_traverse: :struct_value],
    struct_kv: [post_traverse: :struct_kv],
    undefined: [token: :undefined],
    enum_value: [export: true, post_traverse: :enum_value],
    range: [post_traverse: :range],
    void: [token: :void],
    elision: [token: :...]
  )

  defp literal(rest, [value, type], context, _loc, _bytes) do
    {rest, [{:literal, type, value}], context}
  end

  defp struct_ptr(rest, args, context, _loc, _bytes) do
    case args do
      [range, value, "&"] -> {rest, [{:structptr, value, range}], context}
      [value, "&"] -> {rest, [{:structptr, value}], context}
    end
  end

  defp string_value(rest, [to, "..", from, string], context, _loc, _bytes) do
    {rest, [{:substring, string, from..to}], context}
  end

  defp string_value(rest, [string], context, _loc, _bytes) do
    {rest, [{:string, string}], context}
  end

  defp sizeof(rest, [type, "@sizeOf"], context, _loc, _bytes) do
    {rest, [{:sizeof, type}], context}
  end

  defp alignof(rest, [type, "@alignOf"], context, _loc, _bytes) do
    {rest, [{:alignof, type}], context}
  end

  defp as(rest, [value, type, "@as"], context, _loc, _bytes) do
    {rest, [{:as, type, value}], context}
  end

  defp as(rest, ["*", value, type, "@as"], context, _loc, _bytes) do
    {rest, [{:ptr_deref, {:as, type, value}}], context}
  end

  defp ptrcast(rest, [name, "@ptrCast"], context, _loc, _bytes) do
    {rest, [{:ptrcast, name}], context}
  end

  defp enum_value(rest, [value], context, _loc, _bytes) do
    {rest, [{:enum, value}], context}
  end

  defp range(rest, [to, "..", from], context, _loc, _bytes) do
    {rest, [from..to], context}
  end

  def parse(str) do
    case literal(str) do
      {:ok, [result], "", _context, _loc, _bytes} -> result
    end
  end
end
