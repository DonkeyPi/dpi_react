ExUnit.start()

defmodule Tester do
  alias Ash.React.State
  defp nop(), do: fn -> nil end

  def on_callback() do
    receive do
      {:react_cb, callback} ->
        callback.()
    end
  end

  def on_changes() do
    count = State.get_changes()
    if count > 0, do: send(self(), {:react_cb, &nop/0})
  end

  def effect_callback(v1, v2 \\ nil) do
    fn ->
      Buffer.add(v1)

      case v2 do
        nil -> :nop
        _ -> fn -> Buffer.add(v2) end
      end
    end
  end
end

defmodule Buffer do
  defp put(state), do: Process.put(__MODULE__, state)

  def get(), do: Process.get(__MODULE__)

  def start(), do: put("")

  def add(data) do
    put(get() <> data)
  end
end
