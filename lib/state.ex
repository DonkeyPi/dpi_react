defmodule Ash.React.State do
  def start() do
    # assert_raise may leave partial state behind
    put({self(), new(), new()})
  end

  defp new() do
    %{
      ids: [],
      fstate: %{},
      vstate: %{},
      changes: %{},
      callbacks: %{},
      effects: %{}
    }
  end

  def stop(), do: put(nil)
  def get(), do: Process.get(__MODULE__)
  defp put(state), do: Process.put(__MODULE__, state)

  def assert_pid() do
    with tuple <- get(),
         true <- tuple != nil,
         pid <- elem(tuple, 0),
         true <- pid == self() do
      pid
    else
      _ -> raise "Invalid caller: #{inspect(self())}"
    end
  end

  defp assert_root() do
    {_pid, curr, _prev} = get()

    unless curr.ids == [] do
      raise("State path is not root: #{inspect(curr.ids)}")
    end
  end

  ###########################################################
  # Path handling
  ###########################################################

  def push_id(id) do
    {pid, curr, prev} = get()
    ids = [id | curr.ids]
    put({pid, %{curr | ids: ids}, prev})
    ids
  end

  def pop_id() do
    {pid, curr, prev} = get()
    [id | ids] = curr.ids
    put({pid, %{curr | ids: ids}, prev})
    id
  end

  def append_id(id) do
    {_pid, curr, _prev} = get()
    [id | curr.ids]
  end

  ###########################################################
  # State handling
  ###########################################################

  def use_state(id, value) do
    {pid, curr, prev} = get()
    fstate = curr.fstate

    if Map.has_key?(fstate, id) do
      raise("Duplicated state id: #{inspect(id)}")
    end

    # Mark this state id as active.
    fstate = Map.put(fstate, id, true)
    curr = %{curr | fstate: fstate}

    # Get value from frozen previous state.
    # All values need to be carried on state transition.
    value = Map.get(prev.vstate, id, value)

    put({pid, curr, prev})
    value
  end

  def set_state(id, value) do
    {pid, curr, prev} = get()

    # Write value to current state.
    vstate = curr.vstate

    changes = curr.changes
    count = Map.get(changes, id, 0)
    equal = value == vstate[id]
    count = if equal, do: count, else: count + 1
    changes = Map.put(changes, id, count)
    curr = %{curr | changes: changes}

    vstate = Map.put(vstate, id, value)
    curr = %{curr | vstate: vstate}

    put({pid, curr, prev})
  end

  def get_changes() do
    {_pid, curr, _prev} = get()

    for {_id, count} <- curr.changes, reduce: 0 do
      sum -> sum + count
    end
  end

  ###########################################################
  # Callback handling
  ###########################################################

  def use_callback(id, function) do
    {pid, curr, prev} = get()
    callbacks = curr.callbacks

    if Map.has_key?(callbacks, id) do
      raise("Duplicated callback id: #{inspect(id)}")
    end

    # Put on current to always have the newest function.
    callbacks = Map.put(callbacks, id, function)
    curr = Map.put(curr, :callbacks, callbacks)
    put({pid, curr, prev})
  end

  def get_callback(id) do
    {_pid, curr, prev} = get()
    # Callbacks that are used as effects should be defined
    # on same node to shared same lifetime.
    # Callbacks that are used as effects cleanups may be
    # called after or because the node is gone so they
    # need to default to previous state.
    # All callbacks need to be carried on state transition.
    callback = Map.get(prev.callbacks, id, fn -> nil end)
    Map.get(curr.callbacks, id, callback)
  end

  ###########################################################
  # Effects handling
  ###########################################################

  def use_effect(id, function, deps) do
    {pid, curr, prev} = get()
    effects = curr.effects

    if Map.has_key?(effects, id) do
      raise("Duplicated effect id: #{inspect(id)}")
    end

    effect = %{deps: deps, function: function}
    effects = Map.put(effects, id, effect)
    curr = %{curr | effects: effects}

    put({pid, curr, prev})
  end

  def before_markup() do
    {pid, curr, prev} = get()

    # Execute current triggered effects (against current changes).
    # Ignore always and once effects (nil or empty deps).
    # Use with to capture used vars with in a block.
    changes = curr.changes

    effects =
      curr.effects
      |> Enum.map(fn {id, effect} ->
        [_ | parent] = id
        deps = effect.deps

        triggered =
          case deps do
            nil -> false
            [] -> false
            _ -> Enum.all?(deps, fn dep -> Map.get(changes, [dep | parent], 0) > 0 end)
          end

        apply_effect(triggered, id, effect)
      end)
      |> Enum.into(%{})

    # State transition

    # Preserve previous value for active ids.
    fstate = curr.fstate
    mvstate = Map.merge(prev.vstate, curr.vstate)
    mvstate = mvstate |> Map.filter(fn {id, _} -> Map.has_key?(fstate, id) end)

    prev = curr
    prev = %{prev | vstate: mvstate}
    prev = %{prev | effects: effects}
    put({pid, new(), prev})

    # Raise here means model upgrade is corrupt
    assert_root()
  end

  def after_markup() do
    # Raise here means markup build is corrupt
    assert_root()

    {pid, curr, prev} = get()

    # Execute cleanups for removed effects
    effects = curr.effects

    peffects =
      prev.effects
      |> Enum.map(fn {id, effect} ->
        removed = not Map.has_key?(effects, id)
        clean_effect(removed, id, effect)
      end)
      |> Enum.into(%{})

    prev = %{prev | effects: peffects}

    # Execute triggered effects after inheriting previous cleanups.
    # Include only once and always effects.
    effects =
      curr.effects
      |> Enum.map(fn {id, effect} ->
        cleanup = get_in(peffects, [id, :cleanup])
        effect = Map.put(effect, :cleanup, cleanup)
        deps = effect.deps

        triggered =
          case deps do
            nil -> true
            [] -> true
            _ -> false
          end

        apply_effect(triggered, id, effect)
      end)

    curr = %{curr | effects: effects}

    put({pid, curr, prev})
  end

  defp clean_effect(flag, id, effect) do
    if flag do
      case Map.get(effect, :cleanup) do
        nil -> :nop
        cleanup -> cleanup.()
      end

      {id, Map.delete(effect, :cleanup)}
    else
      {id, effect}
    end
  end

  defp apply_effect(flag, id, effect) do
    if flag do
      case Map.get(effect, :cleanup) do
        nil -> :nop
        cleanup -> cleanup.()
      end

      cleanup = effect.function.()

      case is_function(cleanup, 0) do
        true -> {id, Map.put(effect, :cleanup, cleanup)}
        _ -> {id, Map.delete(effect, :cleanup)}
      end
    else
      {id, effect}
    end
  end
end
