defmodule Clr.Air.Instruction.Call do
  defstruct [:fn, :args]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[name cs lineref lparen rparen lbrack rbrack]a)
  Clr.Air.import(Clr.Air.Type, ~w[fn_literal literal]a)

  Pegasus.parser_from_string(
    """
    call <- 'call' lparen (fn_literal / lineref) cs lbrack (arg (cs arg)*)? rbrack rparen
    arg <- lineref / literal / name
    """,
    call: [export: true, post_traverse: :call]
  )

  def call(rest, args, context, _, _) do
    case Enum.reverse(args) do
      ["call", fun | args] ->
        {rest, [%__MODULE__{fn: fun, args: args}], context}
    end
  end
end
