# mix run exs/tui_button.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/1, Keyword.put(opts, :on_event, on_event))
  end

  def main(%{cols: cols, rows: rows}) do
    {count, set_count} = use_state(:count, 0)
    on_delta = fn delta -> set_count.(count + delta) end

    panel :main, size: {cols, rows} do
      label(
        :label,
        origin: {0, 0},
        size: {15, 1},
        text: "#{count}"
      )

      button(
        :increment,
        origin: {0, 1},
        size: {15, 3},
        enabled: rem(count, 3) != 2,
        text: "Increment",
        on_click: fn -> on_delta.(+1) end
      )

      button(
        :decrement,
        origin: {0, 4},
        size: {15, 3},
        text: "Decrement",
        enabled: rem(count, 3) != 0,
        on_click: fn -> on_delta.(-1) end
      )
    end
  end
end

opts = [
  term: Ash.Term.Driver,
  rows: 30,
  cols: 100,
  width: 800,
  height: 480,
  fontpt: "12.8",
  motion: 1,
  pointer: 1,
  bgcolor: "000000",
  title: "Button Demo"
]

Demo.run_and_wait(Ash.Tui.Driver, opts)
