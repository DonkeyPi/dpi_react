defmodule Ash.React.App do
  alias Ash.React.State
  alias Ash.React.Driver
  alias Ash.Node.Builder

  # Port drivers must start on app
  # process to receive exit notices.
  # Driver passed as {module, pid}.
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
  def loop(driver, onevt, func, opts) do
    msg =
      receive do
        {:react_cb, callback} ->
          callback.()
          :react_cb

        msg ->
          msg
      end

    if onevt != nil, do: onevt.(msg)

    cond do
      msg == :react_cb ->
        loop(driver, onevt, func, opts)

      Driver.handles?(driver, msg) ->
        # React state updated in place.
        :ok = Driver.handle(driver, msg)
        # FIXME key to id
        # FIXME  modals
        # FIXME  cleanup
        update(driver, func, opts)
        loop(driver, onevt, func, opts)

      msg == :stop ->
        # FIXME Attempt a clean stop.
        # Stop reason to kill state.
        Process.exit(self(), :stop)

      true ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  # Updates the model for the current state.
  defp update(driver, func, opts) do
    %{models: models} = State.reset_state()
    markup = Builder.build(fn -> func.(opts) end)
    {id, model} = realize(driver, markup, models, root: true)
    Driver.render(driver, id, model)
  end

  defp realize(driver, markup, models, extras \\ []) do
    {id, handler, props, children} = markup
    ids = State.push_id(id)
    {handler, props, children} = eval(handler, props, children)
    children = for child <- children, do: realize(driver, child, models)
    ^id = State.pop_id()
    model = Driver.update(driver, handler, ids, children, props, extras)
    {id, model}
  end

  defp eval(handler, props, children) do
    cond do
      is_function(handler, 1) ->
        props = Enum.into(props, %{})
        res = call(handler, props)
        {_, handler, props, children} = res
        eval(handler, props, children)

      # pass as-is to driver
      true ->
        {handler, props, children}
    end
  end

  defp call(handler, props) do
    case handler.(props) do
      nil -> {nil, Nil, [], []}
      res -> res
    end
  end
end
