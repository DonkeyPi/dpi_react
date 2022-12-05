# mix run exs/tui_color.exs

defmodule Demo do
  use Ash.React, app: true
  use Ash.Tui

  def init(opts) do
    on_event = fn e -> log("Event #{inspect(e)}") end
    run(&main/1, Keyword.put(opts, :on_event, on_event))
  end

  def main(%{cols: cols, rows: rows}) do
    {rgb, set_rgb} = use_state(:rgb, {0xFF, 0xFF, 0xFF})

    {r, g, b} = rgb

    ch_rgb = fn c, inc ->
      {r, g, b} =
        case c do
          :r -> {max(r + inc, 0) |> min(255), g, b}
          :g -> {r, max(g + inc, 0) |> min(255), b}
          :b -> {r, g, max(b + inc, 0) |> min(255)}
        end

      set_rgb.({r, g, b})
    end

    panel :main, size: {cols, rows} do
      for i <- 0..255 do
        c = div(i, 30)
        r = rem(i, 30)

        h =
          Integer.to_string(i, 16)
          |> String.pad_leading(2, "0")

        label({:number, i}, origin: {10 * c, r}, text: "#{h}")

        label({:color, i},
          origin: {10 * c + 2, r},
          back: i,
          text: String.duplicate(" ", 7)
        )
      end

      label(:rgb,
        origin: {82, 20},
        size: {15, 3},
        back: rgb,
        text: "0x#{hex(r, 2)}#{hex(g, 2)}#{hex(b, 2)}"
      )

      button(:r_dw, origin: {82, 24}, text: "R -", on_click: fn -> ch_rgb.(:r, -1) end)
      button(:r_up, origin: {88, 24}, text: "R +", on_click: fn -> ch_rgb.(:r, +1) end)
      button(:g_dw, origin: {82, 25}, text: "G -", on_click: fn -> ch_rgb.(:g, -1) end)
      button(:g_up, origin: {88, 25}, text: "G +", on_click: fn -> ch_rgb.(:g, +1) end)
      button(:b_dw, origin: {82, 26}, text: "B -", on_click: fn -> ch_rgb.(:b, -1) end)
      button(:b_up, origin: {88, 26}, text: "B +", on_click: fn -> ch_rgb.(:b, +1) end)
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
  bgcolor: "000000",
  title: "Color Demo"
]

Demo.run_and_wait(Driver, opts)
