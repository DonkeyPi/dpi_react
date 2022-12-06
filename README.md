# AppShell React

```elixir
defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/2, Keyword.put(opts, :on_event, on_event))
  end

  def main(_react, %{width: width, height: height}) do
    panel :main, width: width, height: height do
      label(:label, text: "Demo")
    end
  end
end

alias Ash.Tui.Driver
opts = [width: 800, height: 480, title: "Demo"]
Demo.run_and_wait(Driver, opts)
```

## App Cycle

- Initialize
  - Setup driver
  - Start state
- Wait event
- On UI event
  - Handle event (driver)
  - Can change UI model
  - Can change react state
- On react callback event
  - Directly execute callback
  - Can change react state
- Push react state (current to previous)
  - Previous data still accesible as default
- Build markup (from updated state)
  - The react API is called in this phase
  - The react API consist of use_XXXX imports
- Calculate effect and cleanup (from state diff)
  - Execute cleanups
  - Execute effects
- Update model (from new markup)
- Render model (driver)
- Go to wait event
