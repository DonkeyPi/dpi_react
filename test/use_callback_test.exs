defmodule Ash.React.UseCallback.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  # Callbacks are required for timers
  # to get the value of state at the
  # time of execution instead of at
  # the time of function definition.
  test "use callback test" do
    State.start()
    {count, set_count} = Api.use_state(:count, 0)
    callback = Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 0

    # This triggers the first refresh.
    set_count.(1)

    receive do
      {:react_ss, callback} -> callback.()
    end

    # Previous setter usually would came from a :react_cb or ui
    # event which in turn triggered a markup regeneration (simulated
    # in the following lines) that refreshes the callback definition
    # and captured value.
    State.push()
    {count, set_count} = Api.use_state(:count, 0)
    Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 1

    # Simulate a timer going off.
    spawn_link(fn -> callback.() end)

    # This triggers the second refresh.
    # Execute <old stored callback> on newer context.
    # One receive for callback the other for set_count
    # within the callback.
    receive do
      {:react_cb, callback} -> callback.()
    end

    receive do
      {:react_ss, callback} -> callback.()
    end

    # We get the expected count value on the third markup generation.
    State.push()
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 2
  end
end
