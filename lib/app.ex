defmodule Ash.React.App do
  alias Ash.React.State
  alias Ash.React.Driver
  alias Ash.Node.Builder

  # Port drivers must start on app
  # process to receive exit notices.
  # Driver passed as {module, pid}.
  def run(func, opts) do
    {driver, opts} = Keyword.pop!(opts, :driver)
    {onevt, opts} = Keyword.pop(opts, :on_event, nil)
    opts = Enum.into(opts, %{})
    state = State.init()
    dom = update(nil, state, nil, func, opts)
    driver = Driver.render(driver, dom)
    loop(driver, onevt, state, dom, func, opts)
  end

  # Reliable code should not depend
  # on proper on exit effects cleanup.
  # Port drivers may die at any time.
  def loop(driver, onevt, state, dom, func, opts) do
    msg =
      receive do
        msg -> msg
      end

    if onevt != nil, do: onevt.(msg)

    cond do
      Driver.handles?(driver, msg) ->
        # React state updated in place.
        :ok = Driver.handle(driver, msg)
        # FIXME key to id
        # FIXME  modals
        # FIXME  cleanup
        dom = update(driver, state, dom, func, opts)
        driver = Driver.render(driver, dom)
        loop(driver, onevt, state, dom, func, opts)

      msg == :stop ->
        # FIXME Attempt a clean stop.
        # Stop reason to kill state.
        Process.exit(self(), :stop)

      true ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  # Updates the model for the current state.
  defp update(driver, state, dom, func, opts) do
    tree =
      case dom do
        nil ->
          %{}

        {_, _, _} ->
          State.reset_state(state)
          Driver.tree(driver)
      end

    markup = Builder.build(fn -> func.(state, opts) end)
    {id, momo} = realize(state, markup, tree, root: true)
    {id, momo, markup}
  end

  # FIXME isolate or publish a behaviour
  # FIXME this assumes modules has init | update | children
  defp realize(state, markup, tree, extras \\ []) do
    {id, handler, opts, inner} = markup
    ids = State.push_id(state, id)
    {module, opts, inner} = eval(state, {handler, opts, inner})
    inner = for item <- inner, do: realize(state, item, tree)
    State.pop_id(state)

    model =
      case Map.get(tree, ids) do
        {^module, model} ->
          module.update(model, opts)

        _ ->
          module.init(opts ++ extras)
      end

    model = module.children(model, inner)
    {id, {module, model}}
  end

  defp eval(state, {handler, opts, inner}) do
    cond do
      is_function(handler) ->
        opts = Enum.into(opts, %{})
        res = eval(state, handler, opts)
        {_, handler, opts, inner} = res
        eval(state, {handler, opts, inner})

      is_atom(handler) ->
        {handler, opts, inner}
    end
  end

  defp eval(state, handler, opts) do
    case handler.(state, opts) do
      nil -> {nil, Nil, [], []}
      res -> res
    end
  end
end
