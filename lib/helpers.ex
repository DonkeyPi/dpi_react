defmodule Ash.React.Helpers do
  def hex(v), do: Integer.to_string(v, 16)
  def hex(v, p), do: Integer.to_string(v, 16) |> String.pad_leading(p, "0")
  def clamp(val, mn, mx), do: min(max(val, mn), mx)
end
