defmodule Ash.React.Test do
  use ExUnit.Case
  alias Ash.React.State
  alias Ash.React.Api

  test "use state test" do
    State.start()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :initial
    set_id.(:value)

    assert_raise RuntimeError, "Duplicated state id: [:id]", fn ->
      Api.use_state(:id, :initial)
    end

    State.reset_state()
    {id, set_id} = Api.use_state(:id, :initial)
    assert id == :value

    spawn_link(fn -> set_id.(:remote) end)

    receive do
      {:react_cb, callback} -> callback.()
    end

    State.reset_state()
    {id, _set_id} = Api.use_state(:id, :initial)
    assert id == :remote
  end
end
