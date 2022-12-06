defmodule Ash.React.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  test "assert pid test" do
    State.start()

    pid = self()

    # API restricted to react process.
    spawn_link(fn ->
      assert_raise RuntimeError, "Invalid caller: #{inspect(self())}", fn ->
        State.assert_pid()
      end

      send(pid, :done)
    end)

    receive do
      :done -> :ok
    end
  end

  test "use state test" do
    State.start()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    set_id.(:value)

    # Cannot be called twice.
    assert_raise RuntimeError, "Duplicated state id: [:id]", fn ->
      Api.use_state(:id, :initial)
    end

    # Last call before reset wins.
    set_id.(:final)

    # Can be called again after reset.
    State.reset()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :final

    # Setters can be called from any process.
    spawn_link(fn -> set_id.(:remote) end)

    # Setters are synchronized to the main process.
    receive do
      {:react_cb, callback} -> callback.()
    end

    State.reset()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :remote
  end

  # Callbacks are required for timers
  # to get the value of state at the
  # time of execution instead of at
  # the time of function definition.
  test "use callback test" do
    State.start()
    {count, set_count} = Api.use_state(:count, 0)
    Api.use_callback(:cb, fn -> set_count.(count + 1) end)

    # This triggers the first refresh.
    set_count.(1)

    # Previous setter usually would came from a :react_cb or ui
    # event which in turn triggered a markup regeneration (simulated
    # in the following lines) that refreshes the callback definition
    # and captured value.
    State.reset()
    {count, set_count} = Api.use_state(:count, 0)
    callback = Api.use_callback(:cb, fn -> set_count.(count + 1) end)

    # Simulate a timer going off.
    spawn_link(fn -> callback.() end)

    # This triggers the second refresh.
    receive do
      {:react_cb, callback} -> callback.()
    end

    # We get the expected count value on the third markup generation.
    State.reset()
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 2
  end
end
