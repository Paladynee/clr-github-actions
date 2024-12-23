defmodule Clr.Air.Instruction.CmpxchgWeak do
  defstruct [:loc, :expected, :desired, :success_mode, :failure_mode]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[cs space lparen rparen newline lvalue literal]a)

  Pegasus.parser_from_string(
    """
    cmpxchg_weak <- 'cmpxchg_weak' lparen literal cs lvalue cs lvalue cs mode cs mode rparen

    mode <- seq_cst
    seq_cst <- 'seq_cst'
    """,
    cmpxchg_weak: [export: true, post_traverse: :cmpxchg_weak],
    seq_cst: [token: :seq_cst]
  )

  defp cmpxchg_weak(
         rest,
         [failure, success, desired, expected, loc, "cmpxchg_weak"],
         context,
         _line,
         _bytes
       ) do
    {rest,
     [
       %__MODULE__{
         loc: loc,
         expected: expected,
         desired: desired,
         success_mode: success,
         failure_mode: failure
       }
     ], context}
  end
end
