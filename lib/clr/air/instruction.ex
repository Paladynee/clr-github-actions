defmodule Clr.Air.Instruction do
  @type t :: %{
          optional(atom) => any(),
          __struct__: module(),
          unused: bool()
        }

  @callback initialize(list()) :: t

  @modules Map.new(
             ~w[dbg_stmt dbg_arg_inline br dbg_inline_block dbg_var_val dbg_var_ptr dbg_empty_stmt assembly trap arg ptr_elem_val 
                ptr_add bitcast alloc store load is_non_null optional_payload add cond_br block repeat loop slice slice_ptr
                struct_field_val cmp_neq switch_br],
             fn instruction ->
               {String.to_atom(instruction),
                instruction |> Macro.camelize() |> then(&Module.concat(Clr.Air.Instruction, &1))}
             end
           )

  def initialize(line_info, instruction) do
    @modules
    |> Map.fetch!(instruction)
    |> then(& &1.initialize(line_info))
  end

  @spec to_code([{non_neg_integer, boolean, t}]) :: %{optional(non_neg_integer) => t}
  def to_code(list) do
    Map.new(list, fn {line, unused, code} -> {line, %{code | unused: unused}} end)
  end
end
