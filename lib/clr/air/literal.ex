defmodule Clr.Air.Literal do
  require Pegasus
  require Clr.Air

  #  # literals are type + value
  #  literal <- int_literal / fn_literal / map_literal / other_literal
  #  int_literal <- langle type cs (int / sizeof / alignof) rangle
  #  fn_literal <- langle fn_type cs fn_value rangle
  #  fn_value <- builtinfunction / name
  #  map_literal <- langle type cs map_value rangle
  #  other_literal <- langle type cs convertible rangle
  #  convertible <- as / name / stringliteral / structptr
  #  as <- '@as' lparen ptr_type cs value rparen
  #  value <- ptrcast / name
  #  ptrcast <- '@ptrCast' lparen name rparen
  #  stringliteral <- dstring (indices)?
  #
  #     indices <- lbrack int '..' int rbrack
  # sizeof <- '@sizeOf' lparen type rparen
  # alignof <- '@alignOf' lparen type rparen
  # 
  # structptr <- '&' map_value
  # 
  # map_value <- '.{' (' ' map_part (', ' map_part)* ' ')? '}' index_str?
  # map_part <- map_kv / number
  # map_kv <- enum_literal ' = ' map_v
  # map_v <- name / number / map_value
  # 
  # index_str <- lbrack number '..' number rbrack

  # defp int_literal(rest, [value, type], context, _line, _bytes)
  #     when is_integer(value) or is_tuple(value) do
  #  {rest, [{:literal, type, value}], context}
  # end
  #
  ## defp fn_literal(rest, [name, :function, type], context, _line, _bytes) do
  ##  {rest, [{:literal, type, {:function, name}}], context}
  ## end
  #
  # defp fn_literal(rest, [name, type], context, _line, _bytes) do
  #  {rest, [{:literal, type, name}], context}
  # end
  #
  # defp map_literal(rest, [literal, type], context, _line, _bytes) do
  #  {rest, [{:literal, type, {:map, literal}}], context}
  # end
  #
  # defp other_literal(rest, [value, type], context, _line, _bytes) do
  #  {rest, [{:literal, type, value}], context}
  # end
  #
  # defp as(rest, [value, type, "@as"], context, _line, _bytes) do
  #  {rest, [{:as, type, value}], context}
  # end
  #
  # defp ptrcast(rest, [name, "@ptrCast"], context, _line, _bytes) do
  #  {rest, [{:ptrcast, name}], context}
  # end

  # defp stringliteral(rest, [to, "..", from, string], context, _line, _bytes) do
  #   {rest, [{:string, string, from..to}], context}
  # end

  # defp structptr(rest, [value, "&"], context, _line, _bytes) do
  #   {rest, [{:structptr, value}], context}
  # end
  # 
  # defp sizeof(rest, [type, "@sizeOf"], context, _line, _bytes) do
  #   {rest, [{:sizeof, type}], context}
  # end
  # 
  # defp alignof(rest, [type, "@alignOf"], context, _line, _bytes) do
  #   {rest, [{:alignof, type}], context}
  # end

  # def parse_literal(str) do
  #   case literal(str) do
  #     {:ok, [result], "", _context, _line, _bytes} -> result
  #   end
  # end
end
