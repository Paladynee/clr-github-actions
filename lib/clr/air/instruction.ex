defmodule Clr.Air.Instruction do
  @type t :: struct()

  @callback initialize(list()) :: t

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

  Clr.Air.import(Clr.Air.Base, ~w[lineref clobbers name int cs space comma lparen rparen langle rangle lbrace rbrace 
                                  lbrack rbrack squoted dquoted dstring colon fatarrow newline notnewline]a)
  Clr.Air.import(Clr.Air.Type, ~w[type typelist literal int_literal fn_literal]a)

  Pegasus.parser_from_string("""
  codeblock <- lbrace newline codeline+ space* rbrace
  codeline <- space* ((lineref (space)? '=' space instruction) / clobbers) newline

  instruction <- dbg_stmt / dbg_inline_block / dbg_arg_inline / dbg_var_val / dbg_var_ptr / dbg_empty_stmt / br / assembly / trap / 
                 arg / ptr_elem_val / ptr_add / bitcast / alloc / store / block / loop / load / is_non_null / cond_br /
                 optional_payload / add / repeat / slice / slice_ptr / struct_field_val / cmp_neq / switch_br / 
                 call / unknown_instruction

  dbg_stmt <- 'dbg_stmt(' intrange ')'
  dbg_inline_block <- 'dbg_inline_block(' name cs fun cs codeblock ')'
  dbg_arg_inline <- 'dbg_arg_inline(' langle name cs name rangle cs dquoted ')'
  dbg_var_val <- 'dbg_var_val(' lineref cs dquoted ')'
  dbg_var_ptr <- 'dbg_var_ptr(' lineref cs dquoted ')'
  dbg_empty_stmt <- 'dbg_empty_stmt()'
  br <- 'br(' lineref cs (name / lineref) ')'
  assembly <- 'assembly(' name cs name cs asm_in cs asm_in cs dstring ')'
  trap <- 'trap('')'
  arg <- 'arg(' type cs dquoted ')'
  ptr_elem_val <- 'ptr_elem_val(' lineref cs (lineref / name) ')'
  ptr_add <- 'ptr_add(' type cs lineref cs (lineref / name) ')'
  bitcast <- 'bitcast(' type cs lineref ')'
  alloc <- 'alloc(' type ')'
  store <- 'store(' (lineref / literal) cs (lineref / name) ')'
  block <- 'block(' type cs codeblock (space clobbers)? ')'
  loop <- 'loop(' type cs codeblock ')'
  load <- 'load(' type cs lineref ')'
  is_non_null <- 'is_non_null(' lineref ')'
  cond_br <- 'cond_br(' lineref cs cond_modifier space codeblock cs cond_modifier space codeblock notnewline # ')'
  optional_payload <- 'optional_payload(' type cs lineref ')'
  add <- 'add(' lineref cs (lineref / name) ')'
  repeat <- 'repeat(' lineref ')'
  slice <- 'slice(' type cs lineref cs lineref ')'
  slice_ptr <- 'slice_ptr(' type cs lineref ')'
  struct_field_val <- 'struct_field_val(' lineref cs int ')'
  cmp_neq <- 'cmp_neq(' lineref cs int_literal ')'
  switch_br <- 'switch_br(' lineref (cs switch_case)* (cs else_case)? (newline space*)? ')'
  call <- 'call(' fn_literal cs lbrack (lineref (cs lineref)*)? rbrack')'

  # an "in" statement for assembly language
  asm_in <- lbrack name rbrack space 'in' space name space '=' space lparen asmfun rparen

  # TODO: build this back into "fn_literal" and type literals.

  fun <- langle 'fn' space lparen name (cs name)* rparen space 'callconv' lparen tag rparen space name cs lparen 'function' space squoted rparen rangle
  asmfun <- langle ('*const' space)? 'fn' space typelist space 'callconv' lparen name rparen space name cs name rangle

  switch_case <- lbrack int_literal (cs int_literal)* rbrack space fatarrow space codeblock 
  else_case <- 'else' space fatarrow space codeblock

  cond_modifier <- 'poi' / 'likely' / 'cold'

  intrange <- int colon int

  # debug tools
  tag <- '.@' ["] [^"]+ ["]

  # for debugging
  unknown_instruction <- name lparen notnewline
  """)

  def initialize(line_info, instruction) do
    @modules
    |> Map.fetch!(instruction)
    |> then(& &1.initialize(line_info))
  end

  @spec to_code([{non_neg_integer, boolean, t}]) :: %{optional(non_neg_integer) => t}
  def to_code(list) do
    Map.new(list)
  end

  defp codeline(rest, [instruction, "=", codeline], context, _line, _bytes) do
    {rest, [{codeline, instruction}], context}
  end

  # to be refactored
  defp asmfun(rest, [name, return_type, callconv, "callconv" | args_rest], context, _line, _bytes) do
    fun =
      case Enum.reverse(args_rest) do
        ["*const", "fn" | param_types] ->
          {:constptr, :fun, name, return_type, callconv, param_types}
      end

    {rest, [fun], context}
  end

  defp asm_in(rest, [fndef, "=", "X", "in", name], context, _line, _bytes) do
    {rest, [{:asm_in, name, fndef}], context}
  end

  defp unknown_instruction(_rest, [rest, instruction], _context, {line, _}, _bytes) do
    raise "unknown instruction \"#{instruction}(#{rest}\" found on line #{line}"
  end

  defp instruction(rest, args, context, _line, _bytes, function) do
    decoded = args |> Enum.slice(1..-2//1) |> Enum.reverse() |> Instruction.initialize(function)
    {rest, [decoded], context}
  end

  defp fun(rest, [call, "function", type, _, "callconv" | rargs], context, _line, _bytes) do
    {rest, [{:function, call, type, Enum.reverse(rargs)}], context}
  end
end
