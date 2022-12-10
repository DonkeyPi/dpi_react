defmodule Ash.React.App do
  alias Ash.React.State
  alias Ash.React.Driver
  alias Ash.Node.Builder

  def run(func, onevt, opts) do
    State.start()
    opts = Enum.into(opts, %{})
    update(func, opts)
    loop(onevt, func, opts)
  end

  def sync(pid, function) do
    case self() do
      ^pid -> function.()
      _ -> send(pid, {:react_cb, function})
    end
  end

  defp nop(), do: fn -> nil end

  # Reliable code should not depend
  # on proper on exit effects cleanup.
  # Port drivers may die at any time.
  defp loop(onevt, func, opts) do
    receive do
      # Flag setters to apply immediatelly.
      {:react_cb, callback} ->
        callback.()
        update(func, opts)
        loop(onevt, func, opts)

      :react_stop ->
        # FIXME Attempt a clean stop.
        # Stop reason to kill state.
        Process.exit(self(), :stop)

      msg ->
        if onevt != nil, do: onevt.(msg)

        case Driver.handles?(msg) do
          true ->
            :ok = Driver.handle(msg)
            update(func, opts)
            loop(onevt, func, opts)

          _ ->
            raise "Unexpected #{inspect(msg)}"
        end
    end
  end

  defp update(func, opts) do
    # Make setters async until next forward.
    State.before_markup()
    build = fn -> func.(opts) end
    markup = Builder.build(build, &visitor/2)
    State.after_markup()
    {id, model} = upgrade(markup)
    :ok = Driver.render(id, model)
    # Trigger a new cycle if changes present.
    count = State.get_changes()
    if count > 0, do: send(self(), {:react_cb, &nop/0})
  end

  defp upgrade(markup) do
    {id, handler, props, children} = markup
    ids = State.push_id(id)

    children =
      for child <- children do
        upgrade(child)
      end

    ^id = State.pop_id()
    node = {handler, props, children}
    model = Driver.update(ids, node)
    {id, model}
  end

  defp visitor(:push, id), do: State.push_id(id)
  defp visitor(:pop, _id), do: State.pop_id()
  defp visitor(:add, _id), do: :nop
end
