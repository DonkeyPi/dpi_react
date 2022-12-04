# mix run exs/demo.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/2, Keyword.put(opts, :on_event, on_event))
  end

  def main(_react, %{cols: cols, rows: rows}) do
    node :main, Panel, size: {cols, rows} do
      node(:label, Label, text: "Demo")
    end
  end
end

alias Ash.Tui.Driver
alias Ash.Tui.Scr.Screen

opts = [
  screen: Screen,
  cols: "100",
  rows: "30",
  bgcolor: "404040",
  fontpt: "12.8",
  title: "Demo"
]

Demo.run_and_wait(Driver, opts)
