defmodule Clr.Air.Instruction do
  @modules Map.new(
             ~w[dbg_stmt dbg_arg_inline br dbg_inline_block dbg_var_val dbg_var_ptr dbg_empty_stmt assembly trap 
                arg ptr_elem_val ptr_add bitcast alloc store load is_non_null optional_payload add cond_br block 
                repeat loop slice slice_ptr struct_field_val cmp_neq switch_br call int_from_ptr sub_wrap div_exact
                slice_len cmp_lt slice_elem_val store_safe cmp_lte unreach sub aggregate_init sub_with_overflow
                cmp_eq add_with_overflow not bit_and ret slice_elem_ptr struct_field_ptr struct_field_ptr_index
                rem is_non_err unwrap_errunion_payload unwrap_errunion_err min cmp_gt ret_safe ret_addr wrap_optional
                intcast atomic_rmw memset memcpy add_wrap
                wrap_errunion_payload wrap_errunion_err array_to_slice cmp_gte bool_or ret_ptr ret_load cmpxchg_weak
                optional_payload_ptr try is_non_null_ptr set_union_tag get_union_tag
                errunion_payload_ptr_set mul_with_overflow optional_payload_ptr_set array_elem_val ptr_elem_ptr
                byte_swap int_from_bool error_name sub_sat bit_or trunc is_null shl_with_overflow shr shl div_trunc
                memset_safe frame_addr atomic_load atomic_store_unordered cmpxchg_strong ptr_slice_ptr_ptr xor
                cmp_vector reduce try_ptr unwrap_errunion_err_ptr clz max ptr_slice_len_ptr tag_name union_init
                bit_reverse atomic_store_monotonic add_sat try_cold abs mod mul mul_wrap ptr_sub],
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
                   ret_addr / ret_load / try / try_ptr / try_cold /
                   # pointer operations
                   ptr_elem_val / ptr_add / slice / slice_ptr / slice_len / slice_elem_val /
                   slice_elem_ptr / struct_field_ptr / struct_field_ptr_index /
                   ptr_elem_ptr / frame_addr / ptr_slice_ptr_ptr / ptr_sub /
                   # memory operations
                   bitcast / alloc / store / loop / load / optional_payload / struct_field_val /
                   int_from_ptr / store_safe / aggregate_init / unwrap_errunion_payload / unwrap_errunion_err /
                   wrap_optional / intcast / memset / memcpy / wrap_errunion_payload /
                   wrap_errunion_err / array_to_slice / optional_payload_ptr / set_union_tag /
                   errunion_payload_ptr_set / optional_payload_ptr_set / array_elem_val /
                   get_union_tag / int_from_bool / error_name / trunc / memset_safe /
                   unwrap_errunion_err_ptr / ptr_slice_len_ptr / tag_name / union_init /
                   # atomic operations
                   atomic_rmw / cmpxchg_weak / atomic_load / atomic_store_unordered / cmpxchg_strong /
                   atomic_store_monotonic /
                   # vector operations
                   reduce / cmp_vector /
                   # test
                   is_non_null / cmp_neq / cmp_lt / cmp_lte / cmp_eq / is_non_err / cmp_gt /
                   is_non_null_ptr / is_null / cmp_gte /
                   # math
                   add / sub_wrap / div_exact / sub / sub_with_overflow / add_with_overflow /
                   not / bit_and / rem / min / add_wrap / bool_or / mul_with_overflow / sub_sat /
                   bit_or / shl_with_overflow / shr / shl / div_trunc / xor / clz / max / add_sat /
                   abs / mod / mul / mul_wrap /
                   # etc
                   assembly / arg / block / byte_swap / bit_reverse /
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
