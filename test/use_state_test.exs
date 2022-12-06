defmodule Ash.React.UseState.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

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

    # Execute 2 state updates.
    receive do
      {:react_ss, callback} -> callback.()
    end

    receive do
      {:react_ss, callback} -> callback.()
    end

    # Can call use_state again after stat push.
    State.push()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :final

    # Setters can be called from any process.
    spawn_link(fn -> set_id.(:remote) end)

    # Execute 1 state update.
    receive do
      {:react_ss, callback} -> callback.()
    end

    State.push()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :remote
  end
end
