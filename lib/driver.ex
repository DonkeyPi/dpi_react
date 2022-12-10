defmodule Ash.React.Driver do
  # Starts the driver process with an initial opts.
  @callback start(opts :: keyword()) :: :ok

  # Extracts the initialized options.
  @callback opts() :: opts :: keyword()

  # Checks if message is to be handled by the driver.
  @callback handles?(msg :: any()) :: true | false

  # Passes a received message to the driver.
  @callback handle(msg :: any()) :: :ok

  # Pushes the final model to the screen.
  @callback render(id :: any(), model :: any()) :: :ok

  # Updates branches of the model from children up to root.
  @callback update(ids :: list(), node :: tuple()) :: model :: any()

  defp get(key), do: Process.get({__MODULE__, key})
  defp put(key, data), do: Process.put({__MODULE__, key}, data)

  def start(module, opts) do
    put(:module, module)
    :ok = module.start(opts)
  end

  def opts(), do: get(:module).opts()
  def handles?(msg), do: get(:module).handles?(msg)
  def handle(event), do: get(:module).handle(event)
  def update(ids, node), do: get(:module).update(ids, node)
  def render(id, model), do: get(:module).render(id, model)
end
