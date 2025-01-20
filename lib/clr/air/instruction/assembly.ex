defmodule Clr.Air.Instruction.Assembly do
  defstruct [:type, :code, clobbers: [], in: [], out: [], ->: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[argument type literal lvalue slotref identifier cs space lparen rparen lbrack rbrack lbrace rbrace dstring]a
  )

  Pegasus.parser_from_string(
    """
    assembly <- 'assembly' lparen type cs asmtype (cs directive)* (cs asm_clobber)* cs dstring rparen
    asmtype <- volatile
    volatile <- 'volatile'

    directive <- asm_io / asm_assign

    asm_io <- lbrack lvalue rbrack space ('in' / 'out') space name_or_reg space '=' space lparen argument rparen

    asm_assign <- lbrack lvalue rbrack space rarrow space '=' name_or_reg 

    name_or_reg <- '='? (lbrace lvalue rbrace) / lvalue

    rarrow <- '->'

    asm_clobber <- '~' lbrace identifier rbrace
    """,
    assembly: [export: true, post_traverse: :assembly],
    asm_io: [post_traverse: :asm_io],
    asm_assign: [post_traverse: :asm_assign],
    asm_clobber: [post_traverse: :asm_clobber],
    volatile: [token: :volatile]
  )

  defp asm_io(rest, [literal, "=", var, "in" | args], context, _loc, _bytes) do
    {rest, [{:in, {var, Enum.reverse(args), literal}}], context}
  end

  defp asm_io(rest, [literal, "=", var, "=", "out" | args], context, _loc, _bytes) do
    {rest, [{:out, {var, Enum.reverse(args), literal}}], context}
  end

  defp asm_assign(rest, [reg, "=", "->", var], context, _loc, _bytes) do
    {rest, [{:->, {var, reg}}], context}
  end

  defp asm_clobber(rest, [name, "~"], context, _loc, _bytes) do
    {rest, [{:clobber, name}], context}
  end

  defp assembly(rest, args, context, _loc, _bytes) do
    result =
      case Enum.reverse(args) do
        ["assembly", type, :volatile | rest] ->
          Enum.reduce(rest, %__MODULE__{type: type}, fn
            {:in, in_data}, acc -> Map.update!(acc, :in, &[in_data | &1])
            {:out, out_data}, acc -> Map.update!(acc, :out, &[out_data | &1])
            {:->, to}, acc -> Map.update!(acc, :->, &[to | &1])
            {:clobber, clobber}, acc -> Map.update!(acc, :clobbers, &[clobber | &1])
            string, acc when is_binary(string) -> %{acc | code: string}
          end)
      end
      |> Map.update!(:in, &Enum.reverse(&1))
      |> Map.update!(:->, &Enum.reverse(&1))

    {rest, [result], context}
  end
end
