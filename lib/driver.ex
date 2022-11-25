defmodule Ash.React.Driver do
  # Doms are expected in Ash.Node format.
  # Events are received as {:event, pid, event}
  # with an opaque (any) event payload.

  # Starts the driver process with an initial dims.
  # The caller pid will receive the event messages.
  @callback start_link(width :: integer(), height :: integer(), title :: binary()) ::
              {:ok, driver :: pid()}

  # Dom versioning required to deal with
  # the asych nature of the events round trip

  # Caller uses this method to apply received
  # events from driver process to the current dom.

  # Locates the event handler and executes it
  # depending on the event implementation it may
  # be received already linked to its target node.

  # This handler may not use passed dom at all
  # or may call a generic dom node locator.
  @callback handle(driver :: pid(), dom :: map(), event :: any()) :: :ok

  # push the updated dom to the screen
  @callback render(driver :: pid(), prev :: map(), next :: map(), diff :: map()) :: :ok

  def start_link(module, width, height, title), do: module.start_link(width, height, title)
  def handle({module, pid}, dom, event), do: module.handle(pid, dom, event)
  def render({module, pid}, prev, next, diff), do: module.render(pid, prev, next, diff)
end
