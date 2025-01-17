use Protoss

defprotocol Clr.Air.Instruction do
  alias Clr.Function
  @callback analyze(struct, non_neg_integer, Function.t()) :: Function.t()
  def analyze(instruction, slot, state)
after
  @modules Map.new(
             ~w[assembly 
                arg ptr_elem_val alloc store optional_payload  
                slice slice_ptr struct_field_val 
                slice_len slice_elem_val store_safe unreach aggregate_init
                ret slice_elem_ptr struct_field_ptr struct_field_ptr_index
                unwrap_errunion_payload unwrap_errunion_err ret_safe ret_addr wrap_optional
                intcast memset memcpy 
                wrap_errunion_payload wrap_errunion_err array_to_slice ret_load
                optional_payload_ptr set_union_tag get_union_tag
                errunion_payload_ptr_set optional_payload_ptr_set array_elem_val ptr_elem_ptr
                error_name trunc
                memset_safe ptr_slice_ptr_ptr
                cmp_vector reduce unwrap_errunion_err_ptr ptr_slice_len_ptr tag_name union_init
                casts dbg controls pointers maths tests atomics mem],
             fn instruction ->
               {String.to_atom(instruction),
                instruction |> Macro.camelize() |> then(&Module.concat(Clr.Air.Instruction, &1))}
             end
           )

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[codeline slotref lvalue literal identifier space lbrace rbrace lparen newline notnewline]a
  )

  # import all parsers from their respective modules.

  for {instruction, module} <- @modules do
    NimbleParsec.defparsecp(instruction, NimbleParsec.parsec({module, instruction}))
  end

  Pegasus.parser_from_string(
    """
    # TODO: reorganize this by category.
    instruction <- # control flow
                   unreach / ret / ret_safe /
                   ret_load /
                   # pointer operations
                   ptr_elem_val / slice / slice_ptr / slice_len / slice_elem_val /
                   slice_elem_ptr / struct_field_ptr / struct_field_ptr_index /
                   ptr_elem_ptr / ptr_slice_ptr_ptr / ptr_slice_len_ptr / 
                   struct_field_val / array_elem_val /
                   # memory operations
                   alloc / store / store_safe /
                   memset / memcpy / memset_safe /
                   # memory operations
                   mem /
                   # inits
                   union_init / aggregate_init / 
                   # casting operations
                   intcast / array_to_slice / trunc /
                   unwrap_errunion_payload / unwrap_errunion_err /
                   unwrap_errunion_err_ptr / wrap_optional / wrap_errunion_payload /
                   wrap_errunion_err / optional_payload_ptr / optional_payload_ptr_set /
                   get_union_tag / set_union_tag / errunion_payload_ptr_set /
                   optional_payload / 
                   # names
                   tag_name / error_name /
                   # debug operations
                   dbg /
                   # casting operations
                   casts /
                   # control operations
                   controls /
                   # atomic operations
                   atomics /
                   # vector operations
                   reduce / cmp_vector /
                   # pointer operations
                   pointers /
                   # test
                   tests /
                   # math
                   maths /
                   # etc
                   assembly / arg /
                   # debug 
                   unknown_instruction

    # for debugging
    unknown_instruction <- identifier lparen notnewline

    argument <- lvalue / literal / slotref
    """,
    instruction: [export: true, parser: true],
    unknown_instruction: [post_traverse: :unknown_instruction],
    argument: [export: true]
  )

  defp unknown_instruction(_rest, [rest, instruction], _context, {slot, _}, _bytes) do
    raise "unknown instruction \"#{instruction}(#{rest}\" found on slot #{slot}"
  end

  # debug tool for parsing a single instruction
  def parse(content) do
    case instruction(content) do
      {:ok, [instruction], rest, _, _, _} when rest in ["", "\n"] -> instruction
    end
  end
end
