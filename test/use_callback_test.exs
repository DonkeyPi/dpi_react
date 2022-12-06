defmodule Ash.React.UseCallback.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  # Callbacks are required for timers to get the value
  # of state at the time of execution instead of at
  # the time of callback function definition.
  test "use callback test" do
    # FORWARD RESETS SYNC TO TRUE
    State.start()

    # MARKUP - SYNC READ / ASYNC WRITE
    State.sync?(false)
    {count, set_count} = Api.use_state(:count, 0)
    callback = Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 0

    # FORWARD RESETS SYNC TO TRUE
    State.forward()
    # This triggers the first refresh.
    set_count.(1)

    # Previous setter usually would came from a :react_cb or ui
    # event which in turn triggered a markup regeneration (simulated
    # in the following lines) that refreshes the callback definition
    # and captured value.
    # A new use_callback is issues but its return discarded to simulate
    # the timer capturing and using the previously returned callback.

    # MARKUP - SYNC READ / ASYNC WRITE
    State.sync?(false)
    {count, set_count} = Api.use_state(:count, 0)
    Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 1

    # Simulate a timer going off.
    # This triggers the second refresh.
    # Execute <old stored callback> on newer context.
    spawn_link(fn -> callback.() end)

    # FORWARD RESETS SYNC TO TRUE
    State.forward()
    Tester.on_callback()

    # We get the expected count value on the third markup generation.
    # MARKUP - SYNC READ / ASYNC WRITE
    State.sync?(false)
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 2
  end
end
