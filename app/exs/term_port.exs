alias Ash.Term.Port

# Found this in Pango documentation about Cairo.
# The default is 96dpi (dots per inch) which corresponds to an average screen as output medium.
# A 10pt font will therefore scale to 10pt * (1/72 pt/inch) * (96 pixel/inch) = 13.3 pixel.

# rpi4 official display works with 100x30x12.8 (16pt * 0.8 factor, with +2 vertical spacing and celing)
port =
  Port.open(
    rows: 30,
    cols: 100,
    width: 800,
    height: 480,
    fontpt: "12.8",
    motion: 1,
    pointer: 1,
    bgcolor: "404040",
    title: "Color Demo"
  )

Port.write!(port, "s")
Port.write!(port, "F228866")
Port.write!(port, "B303030")
Port.write!(port, "w1AABCDEFGHIJKLMNOPQRSTUVWXYZ")
Port.write!(port, "x01y01")
Port.write!(port, "w1Aabcdefghijklmnopqrstuvwxyz")
Port.write!(port, "x02y02")
Port.write!(port, "w0A0123456789")
Port.write!(port, "x03y03")
Port.write!(port, "w20`~!@#$%^&*()-_=+[{]}\\|;:\'\",<.>/?")
Port.write!(port, "x04y04")
# https://mothereff.in/byte-counter
Port.write!(port, "w24┌┐└┘─│╔╗╚╝═║")
Port.write!(port, "x05y05")
Port.write!(port, "r2004│|")

Port.write!(port, "x00y10")
Port.write!(port, "r0A0A0123456789")
Port.write!(port, "x00y1D")
Port.write!(port, "r0A0A0123456789")

Port.write!(port, "x06y06")
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
