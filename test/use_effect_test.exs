defmodule Dpi.UseEffectTest do
  use ExUnit.Case
  alias Dpi.React.State
  alias Dpi.React.Api

  # Effects are all about guaranteed cleanups.
  # Resources that require explicit cleanup to avoid accumulating
  # overtime must be started and stopped from within an effect.

  test "use effect test - always effect without cleanup" do
    Buffer.start()
    State.start()

    # 3 times to check cleanup carry
    State.before_markup()
    Api.use_effect(:e, Tester.effect_callback("0"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, Tester.effect_callback("1"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "01"

    State.before_markup()
    assert Buffer.get() == "01"
    Api.use_effect(:e, Tester.effect_callback("2"))
    assert Buffer.get() == "01"
    State.after_markup()
    assert Buffer.get() == "012"

    # removal
    State.before_markup()
    assert Buffer.get() == "012"
    State.after_markup()
    assert Buffer.get() == "012"

    # reinsertion
    State.before_markup()
    assert Buffer.get() == "012"
    Api.use_effect(:e, Tester.effect_callback("3"))
    assert Buffer.get() == "012"
    State.after_markup()
    assert Buffer.get() == "0123"
  end

  test "use effect test - once effect without cleanup" do
    Buffer.start()
    State.start()

    # 3 times to check cleanup carry
    State.before_markup()
    Api.use_effect(:e, [], Tester.effect_callback("0"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, [], Tester.effect_callback("1"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, [], Tester.effect_callback("2"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "0"

    # removal
    State.before_markup()
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "0"

    # reinsertion
    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, [], Tester.effect_callback("3"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "03"
  end

  test "use effect test - always effect with cleanup" do
    Buffer.start()
    State.start()

    # 3 times to check cleanup carry
    State.before_markup()
    Api.use_effect(:e, Tester.effect_callback("0", "1"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, Tester.effect_callback("2", "3"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "012"

    State.before_markup()
    assert Buffer.get() == "012"
    Api.use_effect(:e, Tester.effect_callback("4", "5"))
    assert Buffer.get() == "012"
    State.after_markup()
    assert Buffer.get() == "01234"

    # simulate removal
    State.before_markup()
    assert Buffer.get() == "01234"
    State.after_markup()
    assert Buffer.get() == "012345"

    # reinsertion
    State.before_markup()
    assert Buffer.get() == "012345"
    Api.use_effect(:e, Tester.effect_callback("6", "7"))
    assert Buffer.get() == "012345"
    State.after_markup()
    assert Buffer.get() == "0123456"
  end

  test "use effect test - once effect with cleanup" do
    Buffer.start()
    State.start()

    # 3 times to check cleanup carry
    State.before_markup()
    Api.use_effect(:e, [], Tester.effect_callback("0", "1"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, [], Tester.effect_callback("2", "3"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, [], Tester.effect_callback("4", "5"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "0"

    # simulate removal
    State.before_markup()
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "01"

    # reinsertion
    State.before_markup()
    assert Buffer.get() == "01"
    Api.use_effect(:e, [], Tester.effect_callback("6", "7"))
    assert Buffer.get() == "01"
    State.after_markup()
    assert Buffer.get() == "016"
  end

  test "use effect test - invalid redefinition" do
    Buffer.start()
    State.start()

    State.before_markup()
    Api.use_effect(:e, Tester.effect_callback("0", "1"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == "0"

    State.before_markup()
    assert Buffer.get() == "0"
    Api.use_effect(:e, [], Tester.effect_callback("2", "3"))
    assert Buffer.get() == "0"

    assert_raise RuntimeError, "Unsupported effect deps change: [:e] => nil -> []", fn ->
      State.after_markup()
    end
  end

  test "use effect test - valid redefinition" do
    Buffer.start()
    State.start()

    State.before_markup()
    Api.use_effect(:e, Tester.effect_callback("0", "1"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == "0"

    # simulate removal
    State.before_markup()
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "01"

    # redefinition after removal
    State.before_markup()
    assert Buffer.get() == "01"
    Api.use_effect(:e, [], Tester.effect_callback("2", "3"))
    assert Buffer.get() == "01"
    State.after_markup()
    assert Buffer.get() == "012"
  end

  # Keep state active all the time or any setter will
  # trigger change because value is not being tracked.
  # The second set_id.(2) will compare to nil.
  test "use effect test - change effect with cleanup" do
    Buffer.start()
    State.start()

    # 3 times to check cleanup carry
    State.before_markup()
    {id, set_id} = Api.use_state(:id, 0)
    assert id == 0
    Api.use_effect(:e, [:id, :od], Tester.effect_callback("0", "1"))
    assert Buffer.get() == ""
    State.after_markup()
    assert Buffer.get() == ""
    # trigger change after markup build
    set_id.(1)

    # change gets applied here
    State.before_markup()
    assert Buffer.get() == "0"
    # trigger change during markup build
    set_id.(2)
    Api.use_state(:id, 0)
    Api.use_effect(:e, [:id, :od], Tester.effect_callback("2", "3"))
    assert Buffer.get() == "0"
    State.after_markup()
    assert Buffer.get() == "0"

    # change gets applied here
    State.before_markup()
    assert Buffer.get() == "012"
    Api.use_state(:id, 0)
    Api.use_effect(:e, [:id, :od], Tester.effect_callback("4", "5"))
    assert Buffer.get() == "012"
    State.after_markup()
    assert Buffer.get() == "012"

    # write same value
    set_id.(2)
    # no change this time
    State.before_markup()
    assert Buffer.get() == "012"
    Api.use_state(:id, 0)
    Api.use_effect(:e, [:id, :od], Tester.effect_callback("6", "7"))
    assert Buffer.get() == "012"
    State.after_markup()
    assert Buffer.get() == "012"

    # simulate removal
    State.before_markup()
    assert Buffer.get() == "012"
    Api.use_state(:id, 0)
    # removals fire cleanup here
    State.after_markup()
    assert Buffer.get() == "0123"

    set_id.(3)
    # reinsertion
    # last setter has no effect
    State.before_markup()
    assert Buffer.get() == "0123"
    Api.use_state(:id, 0)
    Api.use_effect(:e, [:id, :od], Tester.effect_callback("8", "9"))
    assert Buffer.get() == "0123"
    State.after_markup()
    assert Buffer.get() == "0123"

    set_id.(4)
    # this will trigger again
    State.before_markup()
    assert Buffer.get() == "01238"
    Api.use_state(:id, 0)
    Api.use_effect(:e, [:id, :od], Tester.effect_callback("A", "B"))
    assert Buffer.get() == "01238"
    State.after_markup()
    assert Buffer.get() == "01238"
  end
end
