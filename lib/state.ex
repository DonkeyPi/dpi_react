defmodule Ash.React.State do
  def init() do
    pid = self()

    {:ok, agent} =
      Agent.start_link(fn ->
        %{
          pid: pid,
          ids: [],
          state: %{},
          prestate: %{},
          callbacks: %{},
          precallbacks: %{},
          changes: %{},
          effects: %{},
          ieffects: [],
          preffects: %{},
          preieffects: [],
          ceffects: %{},
          shortcut: %{},
          timers: %{},
          timerc: 0,
          modal: nil
        }
      end)

    agent
  end

  def pid(agent) do
    Agent.get(agent, fn map -> map.pid end)
  end

  def get(agent) do
    Agent.get(agent, fn map -> map end)
  end

  def push_id(agent, id) do
    Agent.get_and_update(agent, fn map ->
      ids = [id | map.ids]
      {ids, %{map | ids: ids}}
    end)
  end

  def pop_id(agent) do
    Agent.get_and_update(agent, fn map ->
      [id | tail] = map.ids
      {id, %{map | ids: tail}}
    end)
  end

  def append_id(agent, id) do
    Agent.get(agent, fn map -> [id | map.ids] end)
  end

  def use_state(agent, id, value) do
    Agent.get_and_update(agent, fn map ->
      state = Map.fetch!(map, :state)
      if Map.has_key?(state, id), do: raise("Duplicated state id: #{inspect(id)}")
      prestate = Map.fetch!(map, :prestate)
      value = Map.get(prestate, id, value)
      state = Map.put(state, id, value)
      map = Map.put(map, :state, state)
      {value, map}
    end)
  end

  def set_state(agent, id, value) do
    :ok =
      Agent.update(agent, fn map ->
        state = Map.fetch!(map, :state)
        changes = Map.fetch!(map, :changes)

        {change, state} =
          Map.get_and_update!(state, id, fn curr ->
            {curr != value, value}
          end)

        inc = if change, do: 1, else: 0

        changes =
          Map.update(changes, id, inc, fn curr ->
            curr + inc
          end)

        map = Map.put(map, :state, state)
        map = Map.put(map, :changes, changes)
        map
      end)
  end

  def reset_state(agent) do
    :ok =
      Agent.update(agent, fn map ->
        %{
          pid: map.pid,
          ids: [],
          state: %{},
          prestate: map.state,
          callbacks: %{},
          precallbacks: map.callbacks,
          changes: map.changes,
          effects: %{},
          ieffects: [],
          preffects: map.effects,
          preieffects: map.ieffects,
          ceffects: map.ceffects,
          shortcut: %{},
          timers: map.timers,
          timerc: map.timerc,
          modal: nil
        }
      end)
  end

  def use_callback(agent, id, function) do
    :ok =
      Agent.update(agent, fn map ->
        callbacks = Map.fetch!(map, :callbacks)
        if Map.has_key?(callbacks, id), do: raise("Duplicated callback id: #{inspect(id)}")
        callbacks = Map.put(callbacks, id, function)
        map = Map.put(map, :callbacks, callbacks)
        map
      end)
  end

  def get_callback(agent, id) do
    Agent.get(agent, fn map ->
      # precallbacks required to pass callbacks as effect cleanups
      callback = Map.get(map.precallbacks, id, fn -> nil end)
      Map.get(map.callbacks, id, callback)
    end)
  end

  @spec use_effect(atom | pid | {atom, any} | {:via, atom, any}, any, any, any) :: :ok
  def use_effect(agent, id, function, deps) do
    :ok =
      Agent.update(agent, fn map ->
        effects = Map.fetch!(map, :effects)
        if Map.has_key?(effects, id), do: raise("Duplicated effect id: #{inspect(id)}")
        map = Map.update!(map, :ieffects, fn ieffects -> [id | ieffects] end)
        effects = Map.put(effects, id, {function, deps})
        map = Map.put(map, :effects, effects)
        map
      end)
  end

  def reset_effects(agent) do
    Agent.get_and_update(agent, fn map ->
      changes = Map.fetch!(map, :changes)
      effects = Map.fetch!(map, :effects)
      ieffects = Map.fetch!(map, :ieffects)
      preffects = Map.fetch!(map, :preffects)
      preieffects = Map.fetch!(map, :preieffects)
      ceffects = Map.fetch!(map, :ceffects)

      removed =
        for id <- Enum.reverse(preieffects), reduce: [] do
          list ->
            case Map.has_key?(effects, id) do
              false -> [id | list]
              true -> list
            end
        end

      triggered = for id <- Enum.reverse(ieffects), do: {id, effects[id]}

      triggered =
        Enum.filter(triggered, fn {id, {_function, deps}} ->
          [_ | parent] = id

          case deps do
            nil -> true
            [] -> !Map.has_key?(preffects, id)
            _ -> Enum.all?(deps, fn dep -> Map.get(changes, [dep | parent], 0) > 0 end)
          end
        end)

      cleanups =
        for {id, {_function, _deps}} <- triggered, reduce: removed do
          list -> [id | list]
        end

      {cleanups, ceffects} =
        for id <- cleanups, reduce: {[], ceffects} do
          {list, map} ->
            case Map.get(map, id) do
              nil -> {list, map}
              cleanup -> {[{id, cleanup} | list], Map.delete(map, id)}
            end
        end

      map = Map.put(map, :ceffects, ceffects)
      {{triggered, cleanups}, map}
    end)
  end

  def set_cleanup(agent, id, function) do
    :ok =
      Agent.update(agent, fn map ->
        Map.update!(map, :ceffects, fn ceffects ->
          if Map.has_key?(ceffects, id), do: raise("Duplicated cleanup id: #{inspect(id)}")
          Map.put(ceffects, id, function)
        end)
      end)
  end

  def reset_changes(agent) do
    :ok = Agent.update(agent, fn map -> Map.put(map, :changes, %{}) end)
  end

  def count_changes(agent) do
    Agent.get(agent, fn map -> map_size(map.changes) end)
  end

  def new_timer(agent) do
    Agent.get_and_update(agent, fn map ->
      id = map.timerc

      map =
        Map.update!(map, :timers, fn timers ->
          Map.put(timers, id, nil)
        end)

      {id, %{map | timerc: id + 1}}
    end)
  end

  def get_timer(agent, id) do
    Agent.get(agent, fn map -> map.timers[id] end)
  end

  def set_timer(agent, id, timer) do
    :ok =
      Agent.update(agent, fn map ->
        Map.update!(map, :timers, fn timers ->
          Map.update!(timers, id, fn _ -> timer end)
        end)
      end)
  end

  def clear_timer(agent, id) do
    Agent.get_and_update(agent, fn map ->
      Map.get_and_update!(map, :timers, fn timers ->
        Map.pop(timers, id)
      end)
    end)
  end

  def set_modal(agent, key) do
    :ok =
      Agent.update(agent, fn map ->
        Map.put(map, :modal, key)
      end)
  end

  def get_modal(agent) do
    Agent.get(agent, fn map -> Map.get(map, :modal) end)
  end

  def stop(agent) do
    Agent.stop(agent)
  end
end
