# Athasha React

```elixir
# mix run exs/demo.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/2, Keyword.put(opts, :on_event, on_event))
  end

  def main(_react, %{width: width, height: height}) do
    node :main, Panel, width: width, height: height do
      node(:label, Label, text: "Demo")
    end
  end
end

alias Ash.Tui.Gtk3
opts = [width: 800, height: 480, title: "Demo"]
Demo.run_and_wait(Gtk3, opts)
```
