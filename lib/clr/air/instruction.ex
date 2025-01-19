use Protoss

defprotocol Clr.Air.Instruction do
  alias Clr.Function
  @callback analyze(struct, non_neg_integer, Function.t()) :: Function.t()
  def analyze(instruction, slot, state)
after
  @modules Map.new(
             ~w[assembly 
                arg alloc  
                aggregate_init
                memcpy 
                cmp_vector union_init
                vector 
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
    instruction <- # memory operations
                   alloc /
                   memcpy /
                   # memory operations
                   mem /
                   # inits
                   union_init / aggregate_init /
                   # debug operations
                   dbg /
                   # casting operations
                   casts /
                   # control operations
                   controls /
                   # atomic operations
                   atomics /
                   # vector operations
                   vector /
                   cmp_vector /
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
