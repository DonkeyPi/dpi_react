defmodule Ash.React.Api do
  alias Ash.React.State

  def use_state(id, initial) do
    pid = State.assert_pid()
    ids = State.append_id(id)
    value = State.use_state(ids, initial)

    {value,
     fn value ->
       case self() do
         ^pid ->
           State.set_state(ids, value)

         _ ->
           # Async to support set_state from other processes.
           callback = fn -> State.set_state(ids, value) end
           send(pid, {:react_cb, callback})
       end
     end}
  end

  # Callbacks are required for timers to get the value
  # of state at the time of execution instead of at
  # the time of callback function definition.
  def use_callback(id, function) do
    pid = State.assert_pid()
    ids = State.append_id(id)
    State.use_callback(ids, function)
    # Returns nop function if not found.
    callback = fn -> State.get_callback(ids).() end
    fn -> send(pid, {:react_cb, callback}) end
  end

  # Effects are all about guaranteed cleanups.
  # Resources that require explicit cleanup to avoid accumulating
  # overtime must be started and stopped from within an effect.
  def use_effect(id, function) do
    use_effect(id, nil, function)
  end

  def use_effect(id, deps, callback) do
    _pid = State.assert_pid()
    ids = State.append_id(id)

    function = fn ->
      cleanup = callback.()

      if is_function(cleanup) do
        State.set_cleanup(ids, cleanup)
      end
    end

    State.use_effect(ids, function, deps)

    # Prevent leaks from internal state.
    :ok
  end

  # def set_interval(millis, callback) do
  #   pid = assert_pid()
  #   id = State.new_timer()

  #   callfunc = fn ->
  #     task = State.get_timer(id)
  #     if task != nil, do: callback.()
  #   end

  #   {:ok, task} =
  #     Task.start_link(fn ->
  #       receive do
  #         :start -> nil
  #       end

  #       stream = Stream.interval(millis)

  #       Enum.each(stream, fn _ ->
  #         send(pid, {:cmd, :callback, callfunc})
  #       end)
  #     end)

  #   State.set_timer(id, task)
  #   send(task, :start)

  #   fn ->
  #     # Unlink requires react process.
  #     assert_pid()
  #     task = State.clear_timer(id)

  #     if task != nil do
  #       Process.unlink(task)
  #       Process.exit(task, :kill)
  #     end
  #   end
  # end

  # def set_timeout(millis, callback) do
  #   pid = assert_pid()
  #   id = State.new_timer()

  #   callfunc = fn ->
  #     task = State.clear_timer(id)
  #     if task != nil, do: callback.()
  #   end

  #   # Process.send_after is a cancelable alternative.
  #   {:ok, task} =
  #     Task.start_link(fn ->
  #       receive do
  #         :start -> nil
  #       end

  #       :timer.sleep(millis)
  #       send(pid, {:cmd, :callback, callfunc})
  #     end)

  #   State.set_timer(id, task)
  #   send(task, :start)

  #   fn ->
  #     # Unlink requires react process.
  #     assert_pid()
  #     task = State.clear_timer(id)

  #     if task != nil do
  #       Process.unlink(task)
  #       Process.exit(task, :kill)
  #     end
  #   end
  # end

  # def clear_timer(timer) do
  #   timer.()
  # end

  defmacro log(msg) do
    # Remove Elixir from begining of name.
    module = __CALLER__.module |> Atom.to_string()
    module = module |> String.slice(7, String.length(module))

    quote do
      msg = unquote(msg)
      module = unquote(module)
      # 2022-09-10 20:02:49.684244Z
      now = DateTime.utc_now()
      now = String.slice("#{now}", 11..22)
      IO.puts("#{now} #{inspect(self())} #{module} #{msg}")
    end
  end
end
