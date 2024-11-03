defmodule Zigit do
  use Zig,
    otp_app: :zigit,
    nifs: [..., generate_mandelbrot: [:threaded]],
    zig_code_path: "draw.zig",
    release_mode: :fast

  def draw do
    t = :os.system_time(:millisecond)
    res_x = 1_000
    res_y = 1_000
    img = generate_mandelbrot(res_x, res_y, true)
    # dbg(byte_size(img))
    dbg(:os.system_time(:millisecond) - t)
    {:ok, vimg} = Vix.Vips.Image.new_from_binary(img, res_x, res_y, 3, :VIPS_FORMAT_UCHAR)
    Vix.Vips.Operation.pngsave(vimg, "priv/zigex.png", compression: 2)
    # Vix.Vips.Image.write_to_file(vimg, "priv/zigex.jpg[Q=90]")
  end
end
