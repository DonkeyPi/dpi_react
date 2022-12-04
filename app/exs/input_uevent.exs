alias Ash.Input.Bus

IO.puts("Plug/unplug some devices.")

Bus.register!(:uevent)

loop = fn loop ->
  receive do
    event -> IO.inspect(event)
  end

  loop.(loop)
end

loop.(loop)
