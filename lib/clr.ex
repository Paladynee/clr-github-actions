defmodule Clr do
  alias Clr.Lvalue

  @type type :: ptr_type | array_type | struct_type | scalar_type | typeof_type

  @type ptr_type :: {:ptr, ptr_count, type, meta}
  @type array_type :: {:array, non_neg_integer, type, meta}
  @type struct_type :: {:struct, [type], meta}
  @type scalar_type :: int_type | uint_type | float_type | bool_type 
  @type int_type :: {:i, 0..65535, meta}
  @type uint_type :: {:u, 0..65535, meta}
  @type float_type :: {:f, 16 | 32 | 64 | 80 | 128, meta}
  @type bool_type :: {:bool, meta}
  @type typeof_type :: {:TypeOf, Lvalue.t, meta}

  # TODO: union types

  @type ptr_count :: :one | :many | :slice | :c

  @type slot :: non_neg_integer
  @type meta :: %{optional(atom) => term}

  defguard is_lvalue(lvalue) when elem(lvalue, 0) == :lvalue and is_list(elem(lvalue, 1))

  defguard is_indexed_type(type) when elem(type, 0) == :ptr and
    elem(type, 1) in ~w[one many slice c array]a and is_map(elem(type, 3))

  defguard is_struct_type(type) when elem(type, 0) == :struct and is_map(elem(type, 2))

  defguard is_int_type(type) when elem(type, 0) in ~w[i u] and elem(type, 1) in 0..65535 and is_map(elem(type, 2))

  defguard is_float_type(type) when elem(type, 0) == :f and elem(type, 1) in [16, 32, 64, 80, 128] and is_map(elem(type, 2))

  defguard is_bool_type(type) when elem(type, 0) == :bool and is_map(elem(type, 1))

  defguard is_scalar_type(type) when is_int_type(type) or is_float_type(type) or is_bool_type(type)

  defguard is_typeof_type(type) when elem(type, 0) == :TypeOf and is_lvalue(elem(type, 1)) and is_map(elem(type, 2))

  defguard is_type(type) when 
    is_indexed_type(type) or is_struct_type(type)
    or is_scalar_type(type) or is_typeof_type(type)

  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)
end
