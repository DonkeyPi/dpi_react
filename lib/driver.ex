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
  @callback start_link(opts :: keyword()) :: {:ok, driver :: pid()}

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
  #   curr::keyword()
  #   event::any()
  @callback handle(driver :: pid(), args :: keyword()) :: :ok

  # Push the updated dom to the screen.
  # Mandatory args:
  #   curr::keyword()
  #   next::keyword()
  #   diff::keyword()
  @callback render(driver :: pid(), args :: keyword()) :: :ok

  def start_link(module, opts), do: module.start_link(opts)
  def handle({module, pid}, args), do: module.handle(pid, args)
  def render({module, pid}, args), do: module.render(pid, args)
end
