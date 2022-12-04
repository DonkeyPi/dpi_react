alias Ash.Input.Bus

IO.puts("Plug/unplug some input devices.")

Bus.register!(:hotplug)

loop = fn loop ->
  receive do
    event -> IO.inspect(event)
  end

  loop.(loop)
end

loop.(loop)
