ExUnit.start()

defmodule Buffer do
  defp put(state), do: Process.put(__MODULE__, state)

  def get(), do: Process.get(__MODULE__)

  def start(), do: put("")

  def add(data) do
    put(get() <> data)
  end
end
