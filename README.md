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
  - Can change UI model *
  - Can trigger react state change (async) *
- On react callback event
  - Execute callback directly
  - Can change react state (unique place) *
- Build markup (from updated state)
  - The react API is called in this phase
  - The react API consist of use_XXXX imports
  - This is the only place where state is read
- Calculate effects and cleanups (from state diff)
  - Execute cleanups
    - Cleanups of removed effects
    - Cleanups of about to fire effects
  - Execute triggered effects
  - Can trigger react state change (async) *
- Push react state (current to previous)
  - Previous data still accesible as default
- Update model (from new markup)
  - Driver must no change react state
  - Driver must no trigger UI events
  - New nodes are initialized
  - Existing node are updated
  - Can change UI model *
- Render model (driver)
- Go to wait event
