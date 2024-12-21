defmodule Clr.Air.Literal do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[identifier int cs space dot lparen rparen langle rangle lbrack rbrack lbrace rbrace squoted dstring]a
  )

  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Clr.Air.import(Clr.Air.Type, ~w[type fn_type ptr_type]a)

  Pegasus.parser_from_string(
    """
    # literals are type + value
    literal <- fn_literal / enum_value / other_literal

    fn_literal <- langle fn_type cs lvalue rangle
    other_literal <- langle type cs convertible rangle

    convertible <- int / void / sizeof / alignof / as / string_value / struct_ptr / struct_value / enum_value / lvalue

    as <- '@as' lparen ptr_type cs value rparen (dot "*")?
    value <- ptrcast / lvalue
    ptrcast <- '@ptrCast' lparen lvalue rparen

    string_value <- dstring (indices)?
    indices <- lbrack int '..' int rbrack

    # special builtin functions
    sizeof <- '@sizeOf' lparen type rparen
    alignof <- '@alignOf' lparen type rparen

    struct_ptr <- '&' struct_value range?

    struct_value <- dot lbrace (space ((struct_part (cs struct_part)*) / elision) space)? rbrace
    struct_part <- struct_kv / convertible
    struct_kv <- dot identifier space eq space convertible

    range <- lbrack int '..' int rbrack

    # does this belong here?
    enum_value <- dot identifier
    void <- '{}'

    # private
    eq <- "="
    elision <- "..."
    """,
    literal: [parser: true, export: true],
    fn_literal: [export: true, post_traverse: :literal],
    other_literal: [export: true, post_traverse: :literal],
    string_value: [post_traverse: :string_value],
    alignof: [post_traverse: :alignof],
    sizeof: [post_traverse: :sizeof],
    as: [post_traverse: :as],
    ptrcast: [post_traverse: :ptrcast],
    struct_ptr: [post_traverse: :struct_ptr],
    struct_value: [post_traverse: :struct_value],
    struct_kv: [post_traverse: :struct_kv],
    enum_value: [export: true, post_traverse: :enum_value],
    range: [post_traverse: :range],
    void: [token: :void],
    elision: [token: :...]
  )

  defp literal(rest, [value, type], context, _line, _bytes) do
    {rest, [{:literal, type, value}], context}
  end

  defp struct_ptr(rest, args, context, _line, _bytes) do
    case args do
      [range, value, "&"] -> {rest, [{:structptr, value, range}], context}
      [value, "&"] -> {rest, [{:structptr, value}], context}
    end
  end

  defp string_value(rest, [to, "..", from, string], context, _line, _bytes) do
    {rest, [{:substring, string, from..to}], context}
  end

  defp string_value(rest, [string], context, _line, _bytes) do
    {rest, [{:string, string}], context}
  end

  defp sizeof(rest, [type, "@sizeOf"], context, _line, _bytes) do
    {rest, [{:sizeof, type}], context}
  end

  defp alignof(rest, [type, "@alignOf"], context, _line, _bytes) do
    {rest, [{:alignof, type}], context}
  end

  defp as(rest, [value, type, "@as"], context, _line, _bytes) do
    {rest, [{:as, type, value}], context}
  end

  defp as(rest, ["*", value, type, "@as"], context, _line, _bytes) do
    {rest, [{:ptr_deref, {:as, type, value}}], context}
  end

  defp ptrcast(rest, [name, "@ptrCast"], context, _line, _bytes) do
    {rest, [{:ptrcast, name}], context}
  end

  defp struct_value(rest, args, context, _line, _bytes) do
    {rest, [{:struct, Enum.reverse(args)}], context}
  end

  defp struct_kv(rest, [value, "=", key], context, _line, _bytes) do
    {rest, [{key, value}], context}
  end

  defp enum_value(rest, [value], context, _line, _bytes) do
    {rest, [{:enum, value}], context}
  end

  defp range(rest, [to, "..", from], context, _line, _bytes) do
    {rest, [from..to], context}
  end

  def parse(str) do
    case literal(str) do
      {:ok, [result], "", _context, _line, _bytes} -> result
    end
  end
end
