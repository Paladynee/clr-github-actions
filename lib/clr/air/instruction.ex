defmodule Clr.Air.Instruction do
  @modules Map.new(
             ~w[dbg_stmt dbg_arg_inline br dbg_inline_block dbg_var_val dbg_var_ptr dbg_empty_stmt assembly trap 
                arg ptr_elem_val ptr_add bitcast alloc store load is_non_null optional_payload add cond_br block 
                repeat loop slice slice_ptr struct_field_val cmp_neq switch_br call],
             fn instruction ->
               {String.to_atom(instruction),
                instruction |> Macro.camelize() |> then(&Module.concat(Clr.Air.Instruction, &1))}
             end
           )

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[name space lbrace rbrace lparen newline notnewline]a)

  # import the "codeline" parser
  Clr.Air.import(Clr.Air.Parser, [:codeline])

  # import all parsers from their respective modules.

  for {instruction, mod} <- @modules do
    Clr.Air.import(mod, [instruction])
  end

  Pegasus.parser_from_string(
    """
    # TODO: reorganize this by category.
    instruction <- dbg_stmt / dbg_inline_block / dbg_arg_inline / dbg_var_val / dbg_var_ptr / # dbg_empty_stmt / 
                   br / assembly / trap / arg / ptr_elem_val / ptr_add / bitcast / alloc / store / block / 
                   loop / load / 
                   # is_non_null / cond_br / optional_payload / add / repeat / slice / slice_ptr / 
                   # struct_field_val / cmp_neq / switch_br / call / 
                   unknown_instruction

    # for debugging
    unknown_instruction <- name lparen notnewline
    """,
    instruction: [export: true, parser: true],
    unknown_instruction: [post_traverse: :unknown_instruction]
  )

  defp unknown_instruction(_rest, [rest, instruction], _context, {line, _}, _bytes) do
    raise "unknown instruction \"#{instruction}(#{rest}\" found on line #{line}"
  end

  # debug tool for parsing a single instruction
  def parse(content) do
    case instruction(content) do
      {:ok, [instruction], rest, _, _, _} when rest in ["", "\n"] -> instruction
    end
  end
end
