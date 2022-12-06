defmodule Ash.React.State do
  def start() do
    # assert_raise may leave partial state behind
    put({self(), map(), map()})
  end

  def forward() do
    {pid, curr, _prev} = get()
    put({pid, map(), curr})
  end

  def map() do
    %{
      ids: [],
      fstate: %{},
      vstate: %{},
      changes: %{},
      callbacks: %{},
      sync?: true,
      effects: %{},
      ieffects: [],
      ceffects: %{}
    }
  end

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

  def sync?() do
    {_pid, curr, _prev} = get()
    curr.sync?
  end

  def sync?(value) do
    {pid, curr, prev} = get()
    curr = %{curr | sync?: value}
    put({pid, curr, prev})
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

  def assert_root() do
    {_pid, curr, _prev} = get()

    unless curr.ids == [] do
      raise("State path is not root: #{inspect(curr.ids)}")
    end
  end

  ###########################################################
  # State handling
  ###########################################################

  def use_state(id, value) do
    {pid, curr, prev} = get()
    fstate = curr.fstate
    vstate = curr.vstate

    if Map.has_key?(fstate, id) do
      raise("Duplicated state id: #{inspect(id)}")
    end

    fstate = Map.put(fstate, id, true)
    curr = %{curr | fstate: fstate}

    value = Map.get(prev.vstate, id, value)
    value = Map.get(vstate, id, value)
    # This next put ensures it is carried on
    # next forward even if no set is issued
    # on the current cycle.
    vstate = Map.put(vstate, id, value)
    curr = %{curr | vstate: vstate}

    put({pid, curr, prev})
    value
  end

  def set_state(id, value) do
    {pid, curr, prev} = get()

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

  ###########################################################
  # Callback handling
  ###########################################################

  def use_callback(id, function) do
    {pid, curr, prev} = get()
    callbacks = curr.callbacks

    if Map.has_key?(callbacks, id) do
      raise("Duplicated callback id: #{inspect(id)}")
    end

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

    if Map.has_key?(effects, id) do
      raise("Duplicated effect id: #{inspect(id)}")
    end

    curr = Map.update!(curr, :ieffects, fn ieffects -> [id | ieffects] end)

    effects = Map.put(effects, id, {function, deps})
    curr = %{curr | effects: effects}

    put({pid, curr, prev})
  end

  def set_cleanup(id, function) do
    {pid, curr, prev} = get()

    ceffects = curr.ceffects

    if Map.has_key?(ceffects, id) do
      raise("Duplicated cleanup id: #{inspect(id)}")
    end

    ceffects = Map.put(ceffects, id, function)
    curr = %{curr | ceffects: ceffects}

    put({pid, curr, prev})
  end

  def before_markup() do
    {pid, curr, prev} = get()
    changes = curr.changes
    peffects = prev.effects
    pceffects = prev.ceffects
    pieffects = prev.ieffects

    # Find previous triggered effects (by deps change).
    # Ignore always and once effects (nil or [] deps).
    triggered =
      pieffects
      |> Enum.reverse()
      |> Enum.map(fn id -> {id, peffects[id]} end)
      |> Enum.filter(fn {id, {_function, deps}} ->
        [_ | parent] = id

        case deps do
          nil -> false
          [] -> false
          _ -> Enum.all?(deps, fn dep -> Map.get(changes, [dep | parent], 0) > 0 end)
        end
      end)

    # Get the cleanups for all triggered effects.
    {cleanups, ceffects} =
      for {id, {_function, _deps}} <- triggered, reduce: {[], pceffects} do
        {cleanups, ceffects} ->
          {cleanup, ceffects} = Map.pop(ceffects, id)

          case cleanup do
            nil -> {cleanups, ceffects}
            _ -> {[{id, cleanup} | cleanups], ceffects}
          end
      end

    # Save the trimmed down cleanups to current state.
    prev = Map.put(prev, :ceffects, %{})
    curr = Map.put(curr, :ceffects, ceffects)
    put({pid, curr, prev})

    # Apply cleanups then apply triggered effects (in that order).
    sync?(true)
    Enum.each(cleanups, fn {_id, cleanup} -> cleanup.() end)
    Enum.each(triggered, fn {_id, {function, _deps}} -> function.() end)
    sync?(false)
    # Cleanups for triggered effect get registered at this point.
  end

  def after_markup() do
    {pid, curr, prev} = get()
    effects = curr.effects
    ieffects = curr.ieffects
    ceffects = curr.ceffects
    peffects = prev.effects
    pieffects = prev.ieffects

    # Find removed effects ids.
    # Present in previous state but not in current state.
    removed =
      for id <- Enum.reverse(pieffects), reduce: [] do
        list ->
          case Map.has_key?(effects, id) do
            false -> [id | list]
            true -> list
          end
      end

    # Find current triggered once and always effects.
    triggered =
      ieffects
      |> Enum.reverse()
      |> Enum.map(fn id -> {id, effects[id]} end)
      |> Enum.filter(fn {id, {_function, deps}} ->
        [_ | _tail] = id

        case deps do
          nil -> true
          [] -> !Map.has_key?(peffects, id)
          _ -> false
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
        {cleanups, ceffects} ->
          {cleanup, ceffects} = Map.pop(ceffects, id)

          case cleanup do
            nil -> {cleanups, ceffects}
            _ -> {[{id, cleanup} | cleanups], ceffects}
          end
      end

    # Save the trimmed down cleanups map.
    curr = Map.put(curr, :ceffects, ceffects)
    put({pid, curr, prev})

    # Apply cleanups then apply triggered effects (in that order).
    sync?(true)
    Enum.each(cleanups, fn {_id, cleanup} -> cleanup.() end)
    Enum.each(triggered, fn {_id, {function, _deps}} -> function.() end)
    sync?(false)
    # Cleanups for triggered effect get registered at this point.
  end
end
