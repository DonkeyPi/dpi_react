defmodule Ash.React.State do
  def start() do
    # assert_raise may leave partial state behind
    pid = self()
    put({pid, map(), map()})
  end

  def map(),
    do: %{
      ids: [],
      state: %{},
      changes: %{}
    }

  def pid(), do: get() |> elem(0)
  def stop(), do: put(nil)
  def get(), do: Process.get(__MODULE__)
  def put(map), do: Process.put(__MODULE__, map)

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

  def reset_state() do
    {pid, curr, prev} = get()
    put({pid, map(), curr})
    prev
  end
end
