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
  @callback start(opts :: keyword()) :: state :: any()

  # Extract the initialized option from opaque state.
  @callback opts(state :: any()) :: opts :: keyword()
  @callback tree(state :: any()) :: tree :: map()

  # Extract the initialized option from opaque state.
  @callback handles?(state :: any(), msg :: any()) :: true | false

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
  @callback handle(state :: any(), event :: any()) :: :ok

  # Push the updated dom to the screen.
  # Mandatory args:
  #   dom::keyword()
  @callback render(state :: any(), dom :: keyword()) :: :ok

  def start(module, opts), do: {module, module.start(opts)}
  def opts({module, state}), do: module.opts(state)
  def tree({module, state}), do: module.tree(state)
  def handles?({module, state}, msg), do: module.handles?(state, msg)
  def handle({module, state}, event), do: module.handle(state, event)
  def render({module, state}, dom), do: {module, module.render(state, dom)}
end
