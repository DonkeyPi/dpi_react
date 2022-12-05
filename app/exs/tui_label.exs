# mix run exs/tui_label.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/1, Keyword.put(opts, :on_event, on_event))
  end

  def main(%{cols: cols, rows: rows}) do
    {text, _set_text} = use_state(:text, "text")
    {origin, set_origin} = use_state(:origin, {0, 0})
    {size, set_size} = use_state(:size, {String.length("text"), 1})

    panel :main, size: {cols, rows} do
      label(
        :label,
        origin: origin,
        size: size,
        text: "#{text}"
      )

      button(
        :mode_left,
        origin: {0, 10},
        text: "< Move Left",
        on_click: fn ->
          {c, r} = origin
          set_origin.({c - 1, r})
        end
      )

      button(
        :mode_right,
        origin: {0, 11},
        text: "> Move Right",
        on_click: fn ->
          {c, r} = origin
          set_origin.({c + 1, r})
        end
      )

      button(
        :dec_size,
        origin: {0, 12},
        text: "- Dec Size",
        on_click: fn ->
          {c, r} = size
          set_size.({c - 1, r})
        end
      )

      button(
        :inc_size,
        origin: {0, 13},
        text: "+ Inc Size",
        on_click: fn ->
          {c, r} = size
          set_size.({c + 1, r})
        end
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
