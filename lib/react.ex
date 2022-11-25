defmodule Ash.React do
  alias Ash.React.State

  defmacro __using__(opts) do
    quote do
      use Ash.Node
      import Ash.React

      opts = unquote(opts)

      if Keyword.get(opts, :app, false) do
        import Ash.React.App, only: [run: 2]

        def child_spec(opts) do
          %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [opts]},
            restart: :permanent,
            type: :worker,
            shutdown: 500
          }
        end

        def start_link(opts \\ []) do
          alias Ash.React.App
          alias Ash.React.Driver
          {driver, opts} = Keyword.pop!(opts, :driver)
          # Pass title and dimensions to app.
          title = Keyword.fetch!(opts, :title)
          width = Keyword.fetch!(opts, :width)
          height = Keyword.fetch!(opts, :height)
          # Supervisor restart strategy.
          {delay, opts} = Keyword.pop(opts, :delay, 0)
          :timer.sleep(delay)

          spawn_link(fn ->
            {:ok, pid} = Driver.start_link(driver, width, height, title)
            opts = Keyword.replace!(opts, :driver, {driver, pid})
            # Init is the user defined function that calls run.
            App.init(driver, opts)
          end)
        end

        # Use monitor to avoid setting/restoring trap_exit.
        # Use monitor for stop to work from unlinked process.
        def stop(pid, toms \\ 5000) do
          ref = Process.monitor(pid)

          # Attempt a clean stop.
          send(pid, :stop)

          # Reliable code should not depend
          # on proper on exit effects cleanup.
          receive do
            {:DOWN, ^ref, :process, ^pid, reason} -> reason
          after
            toms ->
              Process.unlink(pid)
              Process.demonitor(pid, ref)
              Process.exit(pid, :kill)
              :kill
          end
        end

        # Use monitor to avoid setting/restoring trap_exit.
        def run_and_wait(driver, opts) do
          opts = Keyword.put(opts, :driver, driver)
          {:ok, pid} = start_link(opts)
          ref = Process.monitor(pid)

          receive do
            {:DOWN, ^ref, :process, ^pid, reason} -> reason
            msg -> raise "unexpected #{inspect(msg)}"
          end
        end
      end
    end
  end

  def use_state(react, id, initial) do
    ids = State.append_id(react, id)
    current = State.use_state(react, ids, initial)
    pid = assert_pid(react)

    {current,
     fn value ->
       case self() == pid do
         true ->
           State.set_state(react, ids, value)

         false ->
           callback = fn -> State.set_state(react, ids, value) end
           send(pid, {:cmd, :callback, callback})
       end
     end}
  end

  def use_callback(react, id, function) do
    assert_pid(react)
    ids = State.append_id(react, id)
    State.use_callback(react, ids, function)
    fn -> State.get_callback(react, ids).() end
  end

  def use_effect(react, id, function) do
    use_effect(react, id, nil, function)
  end

  def use_effect(react, id, deps, callback) do
    assert_pid(react)
    ids = State.append_id(react, id)

    function = fn ->
      cleanup = callback.()

      if is_function(cleanup) do
        State.set_cleanup(react, ids, cleanup)
      end
    end

    State.use_effect(react, ids, function, deps)
  end

  def set_interval(react, millis, callback) do
    pid = assert_pid(react)
    id = State.new_timer(react)

    callfunc = fn ->
      task = State.get_timer(react, id)
      if task != nil, do: callback.()
    end

    {:ok, task} =
      Task.start_link(fn ->
        receive do
          :start -> nil
        end

        stream = Stream.interval(millis)

        Enum.each(stream, fn _ ->
          send(pid, {:cmd, :callback, callfunc})
        end)
      end)

    State.set_timer(react, id, task)
    send(task, :start)

    fn ->
      # Unlink requires react process.
      assert_pid(react)
      task = State.clear_timer(react, id)

      if task != nil do
        Process.unlink(task)
        Process.exit(task, :kill)
      end
    end
  end

  def set_timeout(react, millis, callback) do
    pid = assert_pid(react)
    id = State.new_timer(react)

    callfunc = fn ->
      task = State.clear_timer(react, id)
      if task != nil, do: callback.()
    end

    # Process.send_after is a cancelable alternative.
    {:ok, task} =
      Task.start_link(fn ->
        receive do
          :start -> nil
        end

        :timer.sleep(millis)
        send(pid, {:cmd, :callback, callfunc})
      end)

    State.set_timer(react, id, task)
    send(task, :start)

    fn ->
      # Unlink requires react process.
      assert_pid(react)
      task = State.clear_timer(react, id)

      if task != nil do
        Process.unlink(task)
        Process.exit(task, :kill)
      end
    end
  end

  def clear_timer(timer) do
    timer.()
  end

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

  defp assert_pid(react) do
    # API restricted to react process.
    pid = self()

    case State.pid(react) do
      ^pid -> pid
      pid -> raise "Invalid caller: #{inspect(pid)}"
    end
  end
end
