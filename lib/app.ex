defmodule Ash.React.App do
  alias Ash.React.State
  alias Ash.React.Driver

  # Port drivers must start on app
  # process to receive exit notices.
  # Driver passed as {module, pid}.
  def run(func, opts) do
    {driver, opts} = Keyword.pop!(opts, :driver)
    {one, opts} = Keyword.pop(opts, :on_event, nil)
    opts = Enum.into(opts, %{})
    state = State.init()
    dom = eval(state, func, opts)
    loop(driver, one, state, dom, func, opts)
  end

  # Reliable code should not depend
  # on proper on exit effects cleanup.
  # Port drivers may die at any time.
  def loop(driver = {_, pid}, one, state, prev, func, opts) do
    receive do
      {:event, ^pid, event} ->
        if one != nil, do: one.(event)
        # React state updated in place.
        :ok = Driver.handle(driver, prev, event)
        next = eval(state, func, opts)
        diff = diff(state, prev, next)
        cleanup(state, prev, next, diff)
        :ok = Driver.render(driver, prev, next, diff)

        loop(driver, one, state, next, func, opts)

      :stop ->
        # FIXME Attempt a clean stop.
        # Stop reason to kill state.
        Process.exit(self(), :stop)

      msg ->
        raise "unexpected #{inspect(msg)}"
    end
  end

  # Renders the dom for the current state.
  def eval(state, func, opts) do
    func.(state, opts)
  end

  # Calculates the doms difference.
  def diff(state, prev, next) do
    unused(state)
    unused(prev)
    unused(next)
    raise "not implemented yet"
  end

  # Applies use effect cleanups.
  def cleanup(state, prev, next, diff) do
    unused(state)
    unused(prev)
    unused(next)
    unused(diff)
    raise "not implemented yet"
  end

  defp unused(_var), do: nil
end
