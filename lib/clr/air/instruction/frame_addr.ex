defmodule Clr.Air.Instruction.FrameAddr do
  defstruct []

  require Pegasus

  Pegasus.parser_from_string("frame_addr <- 'frame_addr()'",
    frame_addr: [export: true, post_traverse: :frame_addr]
  )

  def frame_addr(rest, ["frame_addr()"], context, _, _) do
    {rest, [%__MODULE__{}], context}
  end
end
