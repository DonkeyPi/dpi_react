defmodule Dpi.React.Api do
  alias Dpi.React.App
  alias Dpi.React.State
  alias Dpi.React.Timer
  alias Dpi.React.Assert

  def set_handler(handler) do
    App.set_handler(handler)
  end

  def set_tracer(tracer) do
    App.set_tracer(tracer)
  end

  def get_prop(name, value \\ nil) do
    Process.get({__MODULE__, :prop, name}, value)
  end

  def put_prop(name, value) do
    Process.put({__MODULE__, :prop, name}, value)
  end

  def delete_prop(name) do
    Process.delete({__MODULE__, :prop, name})
  end

  def update_prop(name, updater) do
    value = Process.get({__MODULE__, :prop, name})
    value = updater.(value)
    Process.put({__MODULE__, :prop, name}, value)
  end

  def use_state(id, initial) do
    pid = State.assert_pid()
    ids = State.append_id(id)
    value = State.use_state(ids, initial)

    {value,
     fn value ->
       App.sync(pid, :setter, fn ->
         State.set_state(ids, value)
       end)
     end}
  end

  # Callbacks are required for timers to get the value
  # of state at the time of execution instead of at
  # the time of callback function definition.
  def use_callback(id, callback) do
    Assert.assert_cb(callback)
    pid = State.assert_pid()
    ids = State.append_id(id)
    State.use_callback(ids, callback)

    fn ->
      App.sync(pid, :callback, fn ->
        # Returns nop if not found.
        State.get_callback(ids).()
      end)
    end
  end

  # Effects are all about guaranteed cleanups.
  # Resources that require explicit cleanup to avoid accumulating
  # overtime must be started and stopped from within an effect.
  def use_effect(id, callback) do
    use_effect(id, nil, callback)
  end

  def use_effect(id, deps, callback) do
    Assert.assert_deps(deps)
    Assert.assert_cb(callback)
    _pid = State.assert_pid()
    ids = State.append_id(id)
    State.use_effect(ids, callback, deps)
    # Prevent leaks from internal state.
    :ok
  end

  def set_interval(millis, callback) do
    Assert.assert_cb(callback)
    Assert.assert_ms(millis)
    _pid = State.assert_pid()
    Timer.set_interval(millis, callback)
  end

  def set_timeout(millis, callback) do
    Assert.assert_cb(callback)
    Assert.assert_ms(millis)
    _pid = State.assert_pid()
    Timer.set_timeout(millis, callback)
  end

  def clear_timer(timer) do
    # Uses App.sync for process safety.
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
end
