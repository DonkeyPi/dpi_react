defmodule Ash.React.App do
  alias Ash.React.State
  alias Ash.React.Driver
  alias Ash.Node.Builder
  use Ash.React.Events

  @toms 2000

  def run(func, opts) do
    State.start()
    opts = Enum.into(opts, %{})

    # wait first refresh event from driver term
    receive do
      @refresh_event -> :ok
    after
      @toms -> raise "Refresh event timeout"
    end

    update(func, opts)
    loop(func, opts)
  end

  def sync(pid, type, function) do
    case self() do
      ^pid -> function.()
      _ -> send(pid, {:react_sync, type, function})
    end
  end

  def set_handler(handler) do
    Process.put({__MODULE__, :on_event}, handler)
  end

  defp nop(), do: fn -> nil end

  # Reliable code should not depend
  # on proper on exit effects cleanup.
  # Port drivers may die at any time.
  defp loop(func, opts) do
    on_event = Process.get({__MODULE__, :on_event}, fn _ -> :nop end)

    receive do
      # Flag setters to apply immediatelly.
      {:react_sync, type, callback} ->
        on_event.(%{type: :react, key: :sync, flag: type})

        callback.()
        update(func, opts)
        loop(func, opts)

      :react_stop ->
        on_event.(%{type: :react, key: :stop})

        # FIXME Attempt a clean stop.
        # Stop reason to kill state.
        Process.exit(self(), :stop)

      {:event, event} ->
        on_event.(event)

        :ok = Driver.handle(event)
        update(func, opts)
        loop(func, opts)

      msg ->
        raise "Unexpected #{inspect(msg)}"
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
    if count > 0, do: send(self(), {:react_sync, :changes, &nop/0})
  end

  defp upgrade(markup) do
    {id, handler, props, children} = markup
    ids = State.push_id(id)
    :ok = Driver.push(id)

    children =
      for child <- children do
        upgrade(child)
      end

    ^id = State.pop_id()
    :ok = Driver.pop()
    node = {handler, props, children}
    model = Driver.update(ids, node)
    {id, model}
  end

  defp visitor(:push, id), do: State.push_id(id)
  defp visitor(:pop, _id), do: State.pop_id()
  defp visitor(:add, _id), do: :nop
end
