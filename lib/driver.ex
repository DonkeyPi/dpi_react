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

  def start(module, opts), do: module.start(opts)
  def opts(module), do: module.opts()
  def handles?(module, msg), do: module.handles?(msg)
  def handle(module, event), do: module.handle(event)
  def update(module, ids, node), do: module.update(ids, node)
  def render(module, id, model), do: module.render(id, model)
end
