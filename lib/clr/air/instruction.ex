use Protoss

defprotocol Clr.Air.Instruction do
  def analyze(instruction, state)
after
  @modules Map.new(
             ~w[dbg_stmt dbg_arg_inline br dbg_inline_block dbg_var_val dbg_var_ptr dbg_empty_stmt assembly trap 
                arg ptr_elem_val ptr_add bitcast alloc store load optional_payload cond_br block 
                repeat loop slice slice_ptr struct_field_val switch_br call int_from_ptr 
                slice_len slice_elem_val store_safe unreach aggregate_init
                ret slice_elem_ptr struct_field_ptr struct_field_ptr_index
                unwrap_errunion_payload unwrap_errunion_err ret_safe ret_addr wrap_optional
                intcast memset memcpy 
                wrap_errunion_payload wrap_errunion_err array_to_slice ret_ptr ret_load
                optional_payload_ptr try set_union_tag get_union_tag
                errunion_payload_ptr_set optional_payload_ptr_set array_elem_val ptr_elem_ptr
                int_from_bool error_name trunc
                memset_safe frame_addr ptr_slice_ptr_ptr
                cmp_vector reduce try_ptr unwrap_errunion_err_ptr ptr_slice_len_ptr tag_name union_init
                try_cold ptr_sub maths tests atomics],
             fn instruction ->
               {String.to_atom(instruction),
                instruction |> Macro.camelize() |> then(&Module.concat(Clr.Air.Instruction, &1))}
             end
           )

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[codeline lineref lvalue literal identifier space lbrace rbrace lparen newline notnewline]a
  )

  # import all parsers from their respective modules.

  for {instruction, module} <- @modules do
    NimbleParsec.defparsecp(instruction, NimbleParsec.parsec({module, instruction}))
  end

  Pegasus.parser_from_string(
    """
    # TODO: reorganize this by category.
    instruction <- # debug
                   dbg_stmt / dbg_inline_block / dbg_arg_inline / dbg_var_val / dbg_var_ptr / dbg_empty_stmt / 
                   # control flow
                   br / trap / cond_br / repeat / switch_br / call / unreach / ret / ret_safe / ret_ptr /
                   ret_addr / ret_load / try / try_ptr / try_cold / loop /
                   # pointer operations
                   ptr_elem_val / ptr_add / slice / slice_ptr / slice_len / slice_elem_val /
                   slice_elem_ptr / struct_field_ptr / struct_field_ptr_index /
                   ptr_elem_ptr / frame_addr / ptr_slice_ptr_ptr / ptr_sub / ptr_slice_len_ptr / 
                   struct_field_val / array_elem_val /
                   # memory operations
                   alloc / store / load / store_safe /
                   memset / memcpy / memset_safe /
                   # inits
                   union_init / aggregate_init / 
                   # casting operations
                   bitcast / intcast / int_from_ptr / int_from_bool / array_to_slice / trunc /
                   unwrap_errunion_payload / unwrap_errunion_err /
                   unwrap_errunion_err_ptr / wrap_optional / wrap_errunion_payload /
                   wrap_errunion_err / optional_payload_ptr / optional_payload_ptr_set /
                   get_union_tag / set_union_tag / errunion_payload_ptr_set /
                   optional_payload / 
                   # names
                   tag_name / error_name /
                   # atomic operations
                   atomics /
                   # vector operations
                   reduce / cmp_vector /
                   # test
                   tests /
                   # math
                   maths /
                   # etc
                   assembly / arg / block /
                   # debug 
                   unknown_instruction

    # for debugging
    unknown_instruction <- identifier lparen notnewline

    argument <- lvalue / literal / lineref
    """,
    instruction: [export: true, parser: true],
    unknown_instruction: [post_traverse: :unknown_instruction],
    argument: [export: true]
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

defimpl Clr.Air.Instruction, for: Any do
  def analyze(instruction, state) do
    raise "instruction #{inspect(instruction)} not implemented"
  end
end
