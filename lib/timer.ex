defmodule Ash.React.Timer do
  alias Ash.React.App

  def start() do
    # assert_raise may leave partial state behind
    put({self(), 0, %{}})
  end

  defp get(), do: Process.get(__MODULE__)
  defp put(state), do: Process.put(__MODULE__, state)

  defp get_timer(id) do
    {_pid, _count, timers} = get()
    Map.get(timers, id)
  end

  defp set_timer(id, millis, callback) do
    {pid, count, timers} = get()
    ref = Process.send_after(pid, {:react_cb, callback}, millis)
    timers = Map.put(timers, id, ref)
    put({pid, count, timers})
  end

  defp del_timer(id) do
    {pid, count, timers} = get()
    ref = Map.get(timers, id)
    if ref != nil, do: Process.cancel_timer(ref)
    put({pid, count, Map.delete(timers, id)})
  end

  def set_interval(millis, callback) do
    {pid, count, timers} = get()

    callback = fn ->
      ref = get_timer(count)

      if ref != nil do
        callback.()
        set_timer(count, millis, callback)
      end
    end

    # Increment count before set_timer.
    put({pid, count + 1, timers})
    set_timer(count, millis, callback)
    cleanup = fn -> del_timer(count) end
    fn -> App.sync(pid, cleanup) end
  end

  def set_timeout(millis, callback) do
    {pid, count, timers} = get()

    callback = fn ->
      ref = get_timer(count)

      if ref != nil do
        callback.()
        del_timer(count)
      end
    end

    put({pid, count + 1, timers})
    set_timer(count, millis, callback)
    cleanup = fn -> del_timer(count) end
    fn -> App.sync(pid, cleanup) end
  end
end
