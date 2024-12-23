defmodule Clr.Air.Instruction.Call do
  defstruct [:fn, :args]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lvalue fn_literal literal cs lineref lparen rparen lbrack rbrack]a)

  Pegasus.parser_from_string(
    """
    call <- 'call' lparen (fn_literal / lineref) cs lbrack (argument (cs argument)*)? rbrack rparen
    argument <- lineref / literal / lvalue
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
