alias Ash.Tui.Scr.Port

# Found this in Pango documentation about Cairo.
# The default is 96dpi (dots per inch) which corresponds to an average screen as output medium.
# A 10pt font will therefore scale to 10pt * (1/72 pt/inch) * (96 pixel/inch) = 13.3 pixel.

# rpi4 official display works with 100x30x12.8 (16pt * 0.8 factor, with +2 vertical spacing and celing)
port =
  Port.open(
    cols: "100",
    rows: "30",
    bgcolor: "404040",
    fontpt: "12.8",
    title: "Demo"
  )

# Port.write!(port, "m")
Port.write!(port, "s")
Port.write!(port, "F228866")
Port.write!(port, "B303030")
Port.write!(port, "w1AABCDEFGHIJKLMNOPQRSTUVWXYZ")
Port.write!(port, "x0001y0001")
Port.write!(port, "w1Aabcdefghijklmnopqrstuvwxyz")
Port.write!(port, "x0002y0002")
Port.write!(port, "w0A0123456789")
Port.write!(port, "x0003y0003")
Port.write!(port, "w20`~!@#$%^&*()-_=+[{]}\\|;:\'\",<.>/?")
Port.write!(port, "x0004y0004")
# https://mothereff.in/byte-counter
Port.write!(port, "w24┌┐└┘─│╔╗╚╝═║")
Port.write!(port, "x0005y0005")
Port.write!(port, "r2004│|")

Port.write!(port, "x0000y0010")
Port.write!(port, "r0A0A0123456789")
Port.write!(port, "x0000y001D")
Port.write!(port, "r0A0A0123456789")

Port.write!(port, "x0006y0006")
Port.write!(port, "r2002#$")

loop = fn loop ->
  receive do
    {^port, {:data, data}} ->
      IO.puts("Data #{data}")
      loop.(loop)

    {^port, {:exit_status, status}} ->
      IO.puts("Exit #{status}")

    msg ->
      IO.puts("Unexpected #{inspect(msg)}")
  end
end

loop.(loop)
