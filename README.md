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
- `Sync writes start here`
- Handle event
  - On UI event
    - Handle event (driver)
    - Can change UI model *
    - Can trigger react state change
  - On react callback event
    - Execute callback directly
    - Can trigger react state change
- Apply effects (from state diff)
  - Execute cleanups of about to fire effects
  - Execute triggered effects
    - Cleanups get registered after exec
  - Can trigger react state change
- `Sync writes end here`
- Build markup (from updated state)
  - `This is the only place to read state`
  - This is the only place where APIs are called
  - The react API consist of use_XXXX imports
- Apply cleanups (from markup diff)
  - Cleanups of removed effects
  - Can trigger react state change
- Update model (from new markup)
  - Driver should no change react state
  - Driver should no trigger UI events
  - Driver misbehaviour must not impact
  - New nodes are initialized
  - Existing nodes are updated
  - Can change UI model *
- Render model (driver)
- Move react state forward (current to previous)
  - Previous data still accesible as default
- Go to wait event
