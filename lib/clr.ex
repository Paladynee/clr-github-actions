defmodule Clr do
  alias Clr.Lvalue

  @type type :: ptr_type | array_type | struct_type | typeof_type

  @type ptr_type :: {:ptr, ptr_count, type, meta}
  @type array_type :: {:array, non_neg_integer, type, meta}
  @type struct_type :: {:struct, [type], meta}
  @type basic_type :: int_type | uint_type | float_type | bool_type 
  @type int_type :: {:i, non_neg_integer, meta}
  @type uint_type :: {:u, non_neg_integer, meta}
  @type float_type :: {:f, non_neg_integer, meta}
  @type bool_type :: {:bool, meta}
  @type typeof_type :: {:TypeOf, Lvalue.t, meta}

  # TODO: union types

  @type ptr_count :: :one | :many | :slice | :c

  @type slot :: non_neg_integer
  @type meta :: %{optional(atom) => term}

  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)
end
