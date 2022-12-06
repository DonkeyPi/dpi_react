defmodule Ash.React.State do
  def start() do
    # assert_raise may leave partial state behind
    put({self(), map(), map()})
  end

  def push() do
    {pid, curr, prev} = get()
    keep = [:ceffect]
    keep = Map.take(curr, keep)
    new = Map.merge(map(), keep)
    put({pid, new, curr})
    prev
  end

  def map(),
    do: %{
      ids: [],
      state: %{},
      changes: %{},
      callbacks: %{},
      effects: %{},
      ieffects: [],
      ceffects: %{}
    }

  def stop(), do: put(nil)
  defp get(), do: Process.get(__MODULE__)
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
    state = curr.state
    if Map.has_key?(state, id), do: raise("Duplicated state id: #{inspect(id)}")
    value = Map.get(prev.state, id, value)
    state = Map.put(state, id, value)
    put({pid, %{curr | state: state}, prev})
    value
  end

  def set_state(id, value) do
    {pid, curr, prev} = get()
    state = curr.state
    changes = curr.changes
    count = Map.get(changes, id, 0)
    inc = if value == state[id], do: 0, else: 1
    changes = Map.put(changes, id, count + inc)
    state = Map.put(state, id, value)
    curr = %{curr | state: state, changes: changes}
    put({pid, curr, prev})
  end

  ###########################################################
  # Callback handling
  ###########################################################

  def use_callback(id, function) do
    {pid, curr, prev} = get()
    callbacks = curr.callbacks
    if Map.has_key?(callbacks, id), do: raise("Duplicated callback id: #{inspect(id)}")
    callbacks = Map.put(callbacks, id, function)
    curr = Map.put(curr, :callbacks, callbacks)
    put({pid, curr, prev})
  end

  def get_callback(id) do
    {_pid, curr, prev} = get()
    # precallbacks required to pass callbacks as effect cleanups
    callback = Map.get(prev.callbacks, id, fn -> nil end)
    Map.get(curr.callbacks, id, callback)
  end

  ###########################################################
  # Effects handling
  ###########################################################

  def use_effect(id, function, deps) do
    {pid, curr, prev} = get()
    effects = curr.effects
    if Map.has_key?(effects, id), do: raise("Duplicated effect id: #{inspect(id)}")
    curr = Map.update!(curr, :ieffects, fn ieffects -> [id | ieffects] end)
    effects = Map.put(effects, id, {function, deps})
    curr = Map.put(curr, :effects, effects)
    put({pid, curr, prev})
  end

  def set_cleanup(id, function) do
    {pid, curr, prev} = get()

    curr =
      Map.update!(curr, :ceffects, fn ceffects ->
        if Map.has_key?(ceffects, id), do: raise("Duplicated cleanup id: #{inspect(id)}")
        Map.put(ceffects, id, function)
      end)

    put({pid, curr, prev})
  end

  def apply_effects() do
    {pid, curr, prev} = get()
    changes = curr.changes
    effects = curr.effects
    ieffects = curr.ieffects
    ceffects = curr.ceffects
    effects_p = prev.effects
    ieffects_p = prev.ieffects

    # Find removed effect ids.
    # Present on previous iteration but not anymore.
    removed =
      for id <- Enum.reverse(ieffects_p), reduce: [] do
        list ->
          case Map.has_key?(effects, id) do
            false -> [id | list]
            true -> list
          end
      end

    # Find current and triggered effects (by deps change).
    triggered =
      ieffects
      |> Enum.reverse()
      |> Enum.map(fn id -> {id, effects[id]} end)
      |> Enum.filter(fn {id, {_function, deps}} ->
        [_ | parent] = id

        # With deps = [] effect executes only once (on first definition).
        # With deps = [...] effect executes when at one of the deps changes
        # With deps = nil effect executes every time.
        case deps do
          nil -> true
          [] -> !Map.has_key?(effects_p, id)
          _ -> Enum.all?(deps, fn dep -> Map.get(changes, [dep | parent], 0) > 0 end)
        end
      end)

    # Get the cleanup ids for both the triggered and removed effects.
    # Generated list has no duplicates since removed implies not current.
    cleanups =
      for {id, {_function, _deps}} <- triggered, reduce: removed do
        list -> [id | list]
      end

    # Extract all the cleanup callbacks for all the cleanup ids and
    # remove them from the current cleanup map.
    {cleanups, ceffects} =
      for id <- cleanups, reduce: {[], ceffects} do
        {list, map} ->
          case Map.get(map, id) do
            nil -> {list, map}
            cleanup -> {[{id, cleanup} | list], Map.delete(map, id)}
          end
      end

    # Save the trimmed down cleanups map.
    # Cleanups are preserved on state reset.
    curr = Map.put(curr, :ceffects, ceffects)
    put({pid, curr, prev})

    # Return includes both the triggered effects to be executed
    # and the cleanups of both the triggered and the removed.
    # The cleanups of the triggered are included because they
    # need to be executed before executing the effect itself.
    # Executing a triggered effect requires to cleanup a
    # previous version of the same effect if it exists.
    # For newly defined effects a cleanup may not exist yet.
    {triggered, cleanups}
  end
end
