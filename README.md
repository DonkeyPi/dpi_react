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
- Handle event
  - On UI event
    - Handle event (driver)
    - Can change UI model *
    - `Can trigger react state changes`
  - On react callback event
    - Execute callback directly
    - `Can trigger react state changes`
- Apply effects (from state diff)
  - Calculate triggered effect by state change
  - Get cleanups for triggered effects
  - `Restart the state caches`
  - From here on setters overwrite each other
    - Changes cache prevent missing triggers
  - Execute cleanups of about to fire effects
  - Execute triggered effects
    - New cleanups get registered here
  - `Can trigger react state changes`
- Build markup (from updated state)
  - `State expected freezed during markup`
  - `This is the only place to read state`
  - This is the only place where APIs are called
  - The react API consist of use_XXXX imports
  - `The body of the markup may trigger setters`
- Apply cleanups (from markup diff)
  - Cleanups of removed effects
  - `Can trigger react state changes`
- Upgrade model (from new markup)
  - `The model upgrade may trigger setters`
  - `The model upgrade may trigger UI events`
  - on_visible and similars would trigger here
  - on_change and similars would trigger here
  - New nodes are initialized
  - Existing nodes are updated
  - Can change UI model *
- Render model (driver)
- `Trigger callback if changes present`
- Go to wait event
