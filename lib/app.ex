defmodule Ash.React.App do
  alias Ash.React.State
  alias Ash.React.Driver
  alias Ash.Node.Builder

  def run(func, opts) do
    State.start()
    {driver, opts} = Keyword.pop!(opts, :driver)
    {onevt, opts} = Keyword.pop(opts, :on_event, nil)
    opts = Enum.into(opts, %{})
    update(driver, func, opts)
    loop(driver, onevt, func, opts)
  end

  # Reliable code should not depend
  # on proper on exit effects cleanup.
  # Port drivers may die at any time.
  defp loop(driver, onevt, func, opts) do
    receive do
      # Flag setters to apply immediatelly.
      {:react_cb, callback} ->
        callback.()
        update(driver, func, opts)
        loop(driver, onevt, func, opts)

      :react_stop ->
        # FIXME Attempt a clean stop.
        # Stop reason to kill state.
        Process.exit(self(), :stop)

      msg ->
        if onevt != nil, do: onevt.(msg)

        case Driver.handles?(driver, msg) do
          true ->
            :ok = Driver.handle(driver, msg)
            update(driver, func, opts)
            loop(driver, onevt, func, opts)

          _ ->
            raise "Unexpected #{inspect(msg)}"
        end
    end
  end

  defp update(driver, func, opts) do
    # Make setters async until next forward.
    State.before_markup()
    build = fn -> func.(opts) end
    markup = Builder.build(build, &visitor/2)
    State.assert_root()
    State.after_markup()
    {id, model} = realize(driver, markup)
    :ok = Driver.render(driver, id, model)
    State.assert_root()
    State.forward()
  end

  defp realize(driver, markup) do
    {id, handler, props, children} = markup
    ids = State.push_id(id)

    children =
      for child <- children do
        realize(driver, child)
      end

    ^id = State.pop_id()
    node = {handler, props, children}
    model = Driver.update(driver, ids, node)
    {id, model}
  end

  defp visitor(:push, id), do: State.push_id(id)
  defp visitor(:pop, _id), do: State.pop_id()
  defp visitor(:add, _id), do: :nop
end
