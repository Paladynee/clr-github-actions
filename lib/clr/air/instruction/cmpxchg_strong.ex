defmodule Clr.Air.Instruction.CmpxchgStrong do
  defstruct [:loc, :expected, :desired, :success_mode, :failure_mode]

  require Pegasus
  require Clr.Air
  Clr.Air.import(~w[lineref cs space lparen rparen newline lvalue literal]a)

  Pegasus.parser_from_string(
    """
    cmpxchg_strong <- 'cmpxchg_strong' lparen literal cs (lvalue / lineref) cs (lvalue / lineref) cs mode cs mode rparen

    mode <- seq_cst / monotonic
    seq_cst <- 'seq_cst'
    monotonic <- 'monotonic'
    """,
    cmpxchg_strong: [export: true, post_traverse: :cmpxchg_strong],
    seq_cst: [token: :seq_cst],
    monotonic: [token: :monotonic]
  )

  defp cmpxchg_strong(
         rest,
         [failure, success, desired, expected, loc, "cmpxchg_strong"],
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
