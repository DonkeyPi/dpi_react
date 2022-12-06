defmodule Ash.React.UseState.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  test "use state test" do
    # FORWARD RESETS SYNC TO TRUE
    State.start()

    # MARKUP - SYNC READ / ASYNC WRITE
    State.sync?(false)
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial

    # This will be overwriten below.
    set_id.(:value)

    # Cannot use same id twice on same cycle.
    assert_raise RuntimeError, "Duplicated state id: [:id]", fn ->
      Api.use_state(:id, :initial)
    end

    # Last call before forward wins.
    set_id.(:final)

    # FORWARD RESETS SYNC TO TRUE
    State.forward()

    # EVENTS - SYNC WRITE / CAPTURED READS
    Tester.on_callback()
    Tester.on_callback()

    # MARKUP - SYNC READ / ASYNC WRITE
    State.sync?(false)
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :final

    # Setters can be called from any process.
    spawn_link(fn -> set_id.(:remote) end)

    # FORWARD RESETS SYNC TO TRUE
    State.forward()

    # EVENTS - SYNC WRITE / CAPTURED READS
    Tester.on_callback()

    State.sync?(false)
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :remote
  end
end
