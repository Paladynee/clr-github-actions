defmodule Clr.Air.Instruction.Atomics do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument type slotref literal lvalue cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    atomics <- atomic_load_instruction / atomic_store_instruction / atomic_rmw_instruction / cmpxchg_instruction

    atomic_load_instruction <- atomic_load lparen (slotref / literal) cs mode rparen
    atomic_store_instruction <- atomic_store_prefix mode lparen (slotref / literal) cs (slotref / literal) cs mode rparen
    atomic_rmw_instruction <- atomic_rmw lparen argument cs argument cs op cs mode rparen
    cmpxchg_instruction <- cmpxchg_prefix weak_or_strong lparen argument cs argument cs argument cs mode cs mode rparen

    atomic_load <- 'atomic_load'
    atomic_store_prefix <- 'atomic_store_'
    atomic_rmw <- 'atomic_rmw'
    cmpxchg_prefix <- 'cmpxchg_'

    op <- add / sub / or / xchg
    add <- 'Add'
    sub <- 'Sub'
    or <- 'Or'
    xchg <- 'Xchg'

    weak_or_strong <- weak / strong

    mode <- unordered / monotonic / seq_cst / release / acquire
    unordered <- 'unordered'
    monotonic <- 'monotonic'
    seq_cst <- 'seq_cst'
    weak <- 'weak'
    strong <- 'strong'
    release <- 'release'
    acquire <- 'acquire'
    """,
    atomics: [export: true],
    atomic_load_instruction: [post_traverse: :atomic_load_instruction],
    atomic_store_instruction: [post_traverse: :atomic_store_instruction],
    atomic_rmw_instruction: [post_traverse: :atomic_rmw_instruction],
    cmpxchg_instruction: [post_traverse: :cmpxchg_instruction],
    atomic_load: [ignore: true],
    atomic_store_prefix: [ignore: true],
    atomic_rmw: [ignore: true],
    cmpxchg_prefix: [ignore: true],
    unordered: [token: :unordered],
    monotonic: [token: :monotonic],
    seq_cst: [token: :seq_cst],
    add: [token: :add],
    sub: [token: :sub],
    or: [token: :or],
    xchg: [token: :xchg],
    weak: [token: :weak],
    strong: [token: :strong],
    release: [token: :release],
    acquire: [token: :acquire]
  )

  defmodule Load do
    defstruct ~w[from mode]a
  end

  defp atomic_load_instruction(rest, [mode, from], context, _slot, _bytes) do
    {rest, [%Load{from: from, mode: mode}], context}
  end

  defmodule Store do
    defstruct ~w[from to mode]a
  end

  defp atomic_store_instruction(rest, [mode, from, to, mode], context, _slot, _bytes) do
    {rest, [%Store{from: from, to: to, mode: mode}], context}
  end

  defmodule Rmw do
    defstruct ~w[val loc op mode]a
  end

  defp atomic_rmw_instruction(rest, [mode, op, val, loc], context, _slot, _bytes) do
    {rest, [%Rmw{val: val, loc: loc, op: op, mode: mode}], context}
  end

  defmodule Cmpxchg do
    defstruct ~w[strength loc expected desired success_mode failure_mode]a
  end

  defp cmpxchg_instruction(
         rest,
         [failure_mode, success_mode, desired, expected, loc, strength],
         context,
         _slot,
         _bytes
       ) do
    {rest,
     [
       %Cmpxchg{
         failure_mode: failure_mode,
         success_mode: success_mode,
         desired: desired,
         expected: expected,
         loc: loc,
         strength: strength
       }
     ], context}
  end
end
