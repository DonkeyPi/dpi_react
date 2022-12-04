defmodule Sample.Run do
  use GenServer
  require Ash.App

  @millis 1000

  def start_link(opts \\ []) do
    opts = Enum.into(opts, %{})
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Ash.App.log("Init #{inspect(opts)}")
    Ash.App.log("Node: #{Node.self()}")
    Ash.App.log("Cookie: #{Node.get_cookie()}")
    Ash.App.log("Nodes: #{inspect(Node.list())}")
    Process.send_after(self(), :tick, @millis)
    {:ok, opts}
  end

  def handle_info(:tick, state) do
    Ash.App.log("Tick")
    Process.send_after(self(), :tick, @millis)
    {:noreply, state}
  end
end
