defmodule Clr.Air do
  @base ~w[slotref clobbers keep clobber squoted dquoted dstring identifier alpha alnum int cs singleq doubleq comma space colon dot 
           lparen rparen langle rangle lbrace rbrace lbrack rbrack fatarrow newline equals null undefined elision notnewline]a

  @literal ~w[literal fn_literal convertible enum_value]a

  @lvalue ~w[lvalue comptime_struct]a

  @type_ ~w[type fn_type ptr_type enum_literal]a

  @function ~w[codeline codeblock codeblock_clobbers]a

  @instruction ~w[instruction argument]a

  defmacro import(symbols) do
    symbol_map =
      symbols
      |> Macro.expand(__CALLER__)
      |> Enum.map(fn
        symbol when symbol in @base -> {symbol, Clr.Air.Base}
        symbol when symbol in @literal -> {symbol, Clr.Air.Literal}
        symbol when symbol in @lvalue -> {symbol, Clr.Air.Lvalue}
        symbol when symbol in @type_ -> {symbol, Clr.Air.Type}
        symbol when symbol in @function -> {symbol, Clr.Air.Function}
        symbol when symbol in @instruction -> {symbol, Clr.Air.Instruction}
      end)

    quote bind_quoted: [symbol_map: symbol_map] do
      require NimbleParsec

      for {symbol, module} <- symbol_map do
        NimbleParsec.defparsecp(symbol, NimbleParsec.parsec({module, symbol}))
      end
    end
  end

  defmacro un_op(op, module, opts \\ []) do
    op_str = :"#{op}_str"

    parser = """
    #{op} <- #{op_str} lparen argument rparen
    #{op_str} <- '#{op}'
    """

    quote do
      defmodule unquote(module) do
        defstruct [:type, :src]
        use Clr.Air.Instruction
        unquote(default_code(opts))
      end

      Pegasus.parser_from_string(unquote(parser), unquote(parser_opts(op, op_str)))

      def unquote(op)(rest, [value], context, _slot, _bytes) do
        {rest, [%unquote(module){src: value}], context}
      end
    end
  end

  defmacro ty_op(op, module, opts \\ []) do
    op_str = :"#{op}_str"

    parser = """
    #{op} <- #{op_str} lparen type cs argument rparen
    #{op_str} <- '#{op}'
    """

    quote do
      defmodule unquote(module) do
        defstruct [:type, :src]
        use Clr.Air.Instruction
        unquote(default_code(opts))
      end

      Pegasus.parser_from_string(unquote(parser), unquote(parser_opts(op, op_str)))

      def unquote(op)(rest, [slot, type], context, _slot, _bytes) do
        {rest, [%unquote(module){type: type, src: slot}], context}
      end
    end
  end

  defp parser_opts(op, op_str) do
    [
      {op, post_traverse: op},
      {op_str, ignore: true}
    ]
  end

  defp default_code(opts) do
    Keyword.get(
      opts,
      :do,
      quote do
        def analysis(_, _, _), do: raise("unimplemented")
      end
    )
  end

  alias Clr.Air.Instruction

  @type mode :: :clobber | :keep

  @type codeblock() :: %{
          optional({Clr.slot(), mode}) => Instruction.t()
        }

  ### SERVER PART.  Clr.Air stores parsed AIR for each function in an ets
  ### table.  This part of the module manages the storge for this information.

  # if the function is already in the table, return it immediately.
  # if it's not, register that the request has been made, and then complete
  # the callback when the function has been stored.

  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :set, :protected])
    {:ok, %{}}
  end

  def put(function) do
    GenServer.call(__MODULE__, {:put, function})
    function
  end

  defp put_impl(function, _from, state) do
    :ets.insert(__MODULE__, {function.name, function})

    case Map.fetch(state, function.name) do
      {:ok, waiters} ->
        Enum.each(waiters, &GenServer.reply(&1, function))
        {:reply, :ok, Map.delete(state, function.name)}

      :error ->
        {:reply, :ok, state}
    end
  end

  def get(function_name) do
    case :ets.lookup(__MODULE__, function_name) do
      [{^function_name, stored}] -> stored
      [] -> GenServer.call(__MODULE__, {:get, function_name}, :infinity)
    end
  end

  defp get_impl(function, from, state) do
    case Map.fetch(state, function) do
      {:ok, waiters} ->
        {:noreply, Map.put(state, function, [from | waiters])}

      :error ->
        {:noreply, Map.put(state, function, [from])}
    end
  end

  def handle_call({:put, function}, from, state), do: put_impl(function, from, state)
  def handle_call({:get, function_name}, from, state), do: get_impl(function_name, from, state)
end
