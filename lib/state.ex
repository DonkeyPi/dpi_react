defmodule Ash.React.State do
  alias Ash.React.Timer

  def start() do
    # assert_raise may leave partial state behind
    put({self(), new(), new()})
    Timer.start()
  end

  def stop() do
    Timer.stop()
    put(nil)
  end

  defp get(), do: Process.get(__MODULE__)
  defp put(state), do: Process.put(__MODULE__, state)

  defp new() do
    %{
      ids: [],
      flags: %{},
      values: %{},
      changes: %{},
      callbacks: %{},
      effects: %{}
    }
  end

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
    flags = curr.flags

    if Map.has_key?(flags, id) do
      raise("Duplicated state id: #{inspect(id)}")
    end

    # Mark this state id as active.
    flags = Map.put(flags, id, true)
    curr = %{curr | flags: flags}

    # Get value from frozen previous state.
    # All values need to be carried on state transition.
    value = Map.get(prev.values, id, value)

    put({pid, curr, prev})
    value
  end

  def set_state(id, value) do
    {pid, curr, prev} = get()

    # Checking for active id here prevents
    # the frozen on before_markup from working.

    # Allow for transients by checking against
    # prev value and using a boolean flag.
    # Rogue setters impact here.

    # Write value to current state.
    values = curr.values

    changes = curr.changes
    equal = value == Map.get(prev.values, id)
    changes = Map.put(changes, id, not equal)
    curr = %{curr | changes: changes}

    values = Map.put(values, id, value)
    curr = %{curr | values: values}

    put({pid, curr, prev})
  end

  def get_changes() do
    {_pid, curr, _prev} = get()

    for {_id, flag} <- curr.changes, reduce: 0 do
      sum -> if flag, do: sum + 1, else: sum
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
            _ -> Enum.all?(deps, fn dep -> Map.get(changes, [dep | parent], false) end)
          end

        apply_effect(triggered, id, effect)
      end)
      |> Enum.into(%{})

    # State transition

    # Preserve previous value for active ids.
    flags = curr.flags
    mvalues = Map.merge(prev.values, curr.values)
    mvalues = mvalues |> Map.filter(fn {id, _} -> Map.has_key?(flags, id) end)

    prev = curr
    prev = %{prev | values: mvalues}
    prev = %{prev | effects: effects}
    put({pid, new(), prev})

    # Raise here means model upgrade is corrupt
    assert_root()
  end

  def after_markup() do
    # Raise here means markup build is corrupt
    assert_root()

    {pid, curr, prev} = get()

    # Execute cleanups for removed or redefined effects
    effects = curr.effects

    peffects =
      prev.effects
      |> Enum.map(fn {id, peffect} ->
        clean =
          case Map.get(effects, id) do
            nil ->
              true

            effect ->
              equal = peffect.deps == effect.deps
              # function comparison always returns false
              if not equal do
                pdeps = peffect.deps
                deps = effect.deps
                error = "#{inspect(id)} => #{inspect(pdeps)} -> #{inspect(deps)}"
                raise("Unsupported effect deps change: #{error}")
              end

              false
          end

        clean_effect(clean, id, peffect)
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
            [] -> not Map.has_key?(peffects, id)
            _ -> false
          end

        apply_effect(triggered, id, effect)
      end)
      |> Enum.into(%{})

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
