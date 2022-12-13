defmodule Ash.UseCallbackTest do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  # Callbacks are required for timers to get the value
  # of state at the time of execution instead of at
  # the time of callback function definition.
  test "use callback test - callback is honored" do
    State.start()

    State.before_markup()
    {count, set_count} = Api.use_state(:count, 0)
    callback = Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 0
    State.after_markup()

    # Simulate a timer going off.
    spawn_link(fn -> callback.() end)
    Tester.on_callback()

    State.before_markup()
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 1
    State.after_markup()
  end

  test "use callback test - callback refreshes on each cycle" do
    State.start()

    State.before_markup()
    {count, set_count} = Api.use_state(:count, 0)
    callback = Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 0
    State.after_markup()

    set_count.(1)

    State.before_markup()
    {count, set_count} = Api.use_state(:count, 0)
    # New value for count is captured here.
    # Callback reference is not updated.
    Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 1
    State.after_markup()

    # Simulate a timer going off.
    # Timer executes an old reference.
    spawn_link(fn -> callback.() end)
    Tester.on_callback()

    State.before_markup()
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 2
    State.after_markup()
  end

  # Callbacks must survive for one missing cycle to be
  # used as cleanups for effects on removed nodes.
  test "use callback test - callback is preserved once for one missing cycle" do
    State.start()

    State.before_markup()
    {count, set_count} = Api.use_state(:count, 0)
    callback = Api.use_callback(:cb, fn -> set_count.(count + 1) end)
    assert count == 0
    State.after_markup()

    set_count.(2)

    # One missing cycle for callback.
    State.before_markup()
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 2
    State.after_markup()

    # Simulate a timer going off.
    # Timer executes an old reference.
    spawn_link(fn -> callback.() end)
    Tester.on_callback()

    # Callback is preserved but executes outdated function.
    # This callback overwrites set_count.(2).
    # This is an acceptable condition for cleanup callbacks.
    # Care must be take to avoid setter overwrites.
    State.before_markup()
    {count, _set_count} = Api.use_state(:count, 0)
    assert count == 1
    State.after_markup()
  end
end
