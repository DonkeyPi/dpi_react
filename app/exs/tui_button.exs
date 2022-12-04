# mix run exs/tui_button.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/2, Keyword.put(opts, :on_event, on_event))
  end

  def main(react, %{cols: cols, rows: rows}) do
    {count, set_count} = use_state(react, :count, 0)
    on_delta = fn delta -> set_count.(count + delta) end

    node :main, Panel, size: {cols, rows} do
      node(:label, Label, origin: {0, 0}, size: {12, 1}, text: "#{count}")

      node(:increment, Button,
        origin: {0, 1},
        size: {12, 1},
        enabled: rem(count, 3) != 2,
        text: "Increment",
        on_click: fn -> on_delta.(+1) end
      )

      node(:decrement, Button,
        origin: {0, 2},
        size: {12, 1},
        text: "Decrement",
        enabled: rem(count, 3) != 0,
        on_click: fn -> on_delta.(-1) end
      )
    end
  end
end

alias Ash.Tui.Driver
alias Ash.Tui.Scr.Screen

opts = [
  screen: Screen,
  rows: "30",
  cols: "100",
  fontpt: "12.8",
  bgcolor: "404040",
  title: "Demo"
]

Demo.run_and_wait(Driver, opts)