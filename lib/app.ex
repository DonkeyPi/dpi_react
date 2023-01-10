defmodule Dpi.React.App do
  alias Dpi.React.State
  alias Dpi.React.Driver
  alias Dpi.Node.Builder

  def run(func, opts) do
    State.start()
    opts = Enum.into(opts, %{})
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
    Process.put({__MODULE__, :handler}, handler)
  end

  def set_tracer(tracer) do
    Process.put({__MODULE__, :tracer}, tracer)
  end

  defp loop(func, opts) do
    handler = Process.get({__MODULE__, :handler}, &nop/1)
    tracer = Process.get({__MODULE__, :tracer}, &nop/1)

    receive do
      {:react_sync, type, callback} ->
        handler.(%{type: :react, key: :sync, flag: type})
        begin = tracer.(:begin)
        callback.()
        update(func, opts)
        tracer.(begin)
        loop(func, opts)

      {:event, event} ->
        handler.(event)
        begin = tracer.(:begin)
        :ok = Driver.handle(event)
        update(func, opts)
        tracer.(begin)
        loop(func, opts)

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp update(func, opts) do
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

  defp nop(), do: :nop
  defp nop(_), do: :nop
end
