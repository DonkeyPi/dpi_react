# mix run exs/tui_label.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/2, Keyword.put(opts, :on_event, on_event))
  end

  def main(_react, %{cols: cols, rows: rows}) do
    node :main, Panel, size: {cols, rows} do
      for c <- 0..9 do
        for r <- 0..29 do
          b = r + 30 * c
          h = Integer.to_string(b) |> String.pad_leading(3, "0")

          if b < 256 do
            node({:label, b}, Label, origin: {10 * c, r}, back: b, text: "Color #{h}")
          end
        end
      end
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
