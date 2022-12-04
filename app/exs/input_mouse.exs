alias Ash.Input.Bus

IO.puts("Move or click a mouse.")

Bus.register!(:mouse)

loop = fn loop ->
  receive do
    event -> IO.inspect(event)
  end

  loop.(loop)
end

loop.(loop)
