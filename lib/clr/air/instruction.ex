use Protoss

defprotocol Clr.Air.Instruction do
  # this protocol is used for the "default implementation" of the analyze function.

  alias Clr.Function
  @type t :: struct
  @callback analyze(struct, non_neg_integer, Function.t(), config) :: Function.t()
  def analyze(instruction, slot, state, config)
after
  defstruct []
  @type config :: %__MODULE__{}

  def always, do: []
  def when_kept, do: []

  @modules Map.new(
             ~w[assembly vector casts dbg control_flow pointers maths tests atomics function mem],
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
    instruction <- mem / dbg / casts / control_flow / atomics / vector /
                   pointers / tests / maths / assembly / function /
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
