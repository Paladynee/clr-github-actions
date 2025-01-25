use Protoss

defprotocol Clr.Air.Instruction do
  # this protocol is used for the "default implementation" of the analyze function.

  alias Clr.Block
  @type t :: struct

  @callback slot_type(t, arity, Block.t()) :: {Clr.Type.t(), Block.t()}
  def slot_type(t, arg_index, block)
after
  defstruct []
  @type config :: %__MODULE__{}

  @callback analyze(struct, non_neg_integer, Block.t(), config) :: Block.t()

  # analyze is optional because we provide a default implementation.
  @optional_callbacks analyze: 4

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

  @spec analyze(struct, non_neg_integer, Block.t(), config) :: Block.t()
  def analyze(%module{} = struct, slot, block, config) do
    if function_exported?(module, :analyze, 4) do
      module.analyze(struct, slot, block, config)
    else
      {:cont, block}
    end
  end

  # default slot type functions
  defmacro default_slot_type_function(instr_type) do
    case instr_type do
      :ty_op ->
        quote do
          def slot_type(%{type: type, src: {src, _}}, _, block) when is_integer(src) do
            alias Clr.Block
            alias Clr.Type
            {src_type, block} = Block.fetch_up!(block, src)

            res_type =
              type
              |> Type.from_air()
              |> Type.put_meta(Type.get_meta(src_type))

            {res_type, block}
          end

          def slot_type(%{type: type}, _, block) do
            alias Clr.Type
            {Type.from_air(type), block}
          end

          defoverridable slot_type: 3
        end

      {:un_op, type} ->
        quote do
          def slot_type(%{src: {src, _}}, _, block) when is_integer(src) do
            alias Clr.Block
            alias Clr.Type
            {src_type, block} = Block.fetch_up!(block, src)

            res_type =
              unquote(type)
              |> Type.from_air()
              |> Type.put_meta(Type.get_meta(src_type))

            {res_type, block}
          end

          def slot_type(_, _, block) do
            alias Clr.Type
            {Type.from_air(unquote(type)), block}
          end
        end
    end
  end
end
