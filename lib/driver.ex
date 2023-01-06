defmodule Dpi.React.Driver do
  # Starts the driver process with an initial opts.
  @callback start(opts :: keyword()) :: {:ok, opts :: keyword()}

  # Passes a received event to the driver.
  @callback handle(event :: map()) :: :ok

  # Pushes the final model to the screen.
  @callback render(id :: any(), model :: any()) :: :ok

  # Updates branches of the model from children up to root.
  @callback update(ids :: list(), node :: tuple()) :: model :: any()

  # Model upgrade navigation
  @callback push(id :: any()) :: :ok
  @callback pop() :: :ok

  defp get(key), do: Process.get({__MODULE__, key})
  defp put(key, data), do: Process.put({__MODULE__, key}, data)

  def start(module, opts) do
    put(:module, module)
    module.start(opts)
  end

  def pop(), do: get(:module).pop()
  def push(id), do: get(:module).push(id)
  def handle(event), do: get(:module).handle(event)
  def update(ids, node), do: get(:module).update(ids, node)
  def render(id, model), do: get(:module).render(id, model)
end
