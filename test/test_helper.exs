ExUnit.start()

defmodule Tester do
  def on_callback() do
    receive do
      {:react_cb, callback} ->
        callback.()
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
