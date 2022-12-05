defmodule Ash.React.Driver do
  # Doms are expected in Ash.Node format.
  # Events are received as {:event, pid, event}
  # with an opaque (any) event payload.

  # Starts the driver process with an initial dims.
  # The caller pid will receive the event messages.
  # Mandatory opts:
  #   width::integer()
  #   height::integer()
  #   title::binary()
  @callback start(opts :: keyword()) :: :ok

  # Extract the initialized option from opaque state.
  @callback opts() :: opts :: keyword()

  # Extract the initialized option from opaque state.
  @callback handles?(msg :: any()) :: true | false

  # Dom versioning required to deal with
  # the asych nature of the events round trip

  # Caller uses this method to apply received
  # events from driver process to the current dom.

  # Locates the event handler and executes it
  # depending on the event implementation it may
  # be received already linked to its target node.

  # This handler may not use passed dom at all
  # or may call a generic dom node locator.
  # Mandatory args:
  #   dom::keyword()
  #   event::any()
  @callback handle(event :: any()) :: :ok

  # Push the updated dom to the screen.
  # Mandatory args:
  #   dom::keyword()
  @callback render(id :: any(), model :: any()) :: :ok

  # Opaque model handling
  @callback update(ids :: list(), node :: tuple()) :: model :: any()

  def start(module, opts), do: module.start(opts)
  def opts(module), do: module.opts()
  def handles?(module, msg), do: module.handles?(msg)
  def handle(module, event), do: module.handle(event)
  def render(module, id, model), do: module.render(id, model)
  def update(module, ids, node), do: module.update(ids, node)
end
