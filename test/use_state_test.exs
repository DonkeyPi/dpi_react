defmodule Dpi.UseStateTest do
  use ExUnit.Case
  alias Dpi.React.State
  alias Dpi.React.Api

  test "use state test - initial honored" do
    State.start()

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    State.after_markup()
  end

  test "use state test - duplicated id detected" do
    State.start()

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :initial

    # Cannot use same id twice on same cycle.
    assert_raise RuntimeError, "Duplicated state id: [:id]", fn ->
      Api.use_state(:id, :initial)
    end

    State.after_markup()
  end

  test "use state test - setters outside markup are honored" do
    State.start()

    State.before_markup()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    State.after_markup()

    set_id.(:value)

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :value
    State.after_markup()
  end

  test "use state test - setters inside markup are honored" do
    State.start()

    State.before_markup()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    set_id.(:value)
    State.after_markup()

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :value
    State.after_markup()
  end

  test "use state test - state is frozen on before_markup" do
    State.start()

    State.before_markup()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    State.after_markup()

    set_id.(:frozen)

    State.before_markup()
    # This setter is delayed until next markup build.
    set_id.(:value)
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :frozen
    State.after_markup()

    # Value is honored on next markup build.
    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :value
    State.after_markup()
  end

  test "use state test - state is reset after a missing cycle" do
    State.start()

    State.before_markup()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    State.after_markup()

    set_id.(:value)

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :value
    State.after_markup()

    # Missing cycle
    State.before_markup()
    State.after_markup()

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    State.after_markup()
  end

  test "use state test - state is preserved even if not written to" do
    State.start()

    State.before_markup()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    State.after_markup()

    set_id.(:value)

    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :value
    State.after_markup()

    # Not written in last cycle
    State.before_markup()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :value
    State.after_markup()
  end
end
