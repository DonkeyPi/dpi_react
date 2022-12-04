alias Ash.Input.Bus

IO.puts("Press some keyboard keys.")

Bus.register!(:keyboard)

loop = fn loop ->
  receive do
    event -> IO.inspect(event)
  end

  loop.(loop)
end

loop.(loop)
