defmodule Ash.React.Assert do
  def assert_deps(nil), do: :ok
  def assert_deps(deps) when is_list(deps), do: :ok
  def assert_deps(deps), do: raise("Invalid deps #{inspect(deps)}")

  def assert_cb(cb) when is_function(cb, 0), do: :ok
  def assert_cb(cb), do: raise("Invalid callback #{inspect(cb)}")

  def assert_ms(ms) when ms >= 0, do: :ok
  def assert_ms(ms), do: raise("Invalid duration in (ms) #{inspect(ms)}")
end
