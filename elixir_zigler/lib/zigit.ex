defmodule Zigit do
  use Zig,
    otp_app: :zigit,
    nifs: [..., generate_mandelbrot: [:threaded]],
    zig_code_path: "unsym.zig"

  # release_mode: :fast

  def draw do
    t = :os.system_time(:microsecond)
    res_x = 40_000
    res_y = 30_000
    max_iter = 500

    # tl_x = -2.1
    # tl_y = 1.2
    # br_x = 0.6
    # br_y = -1.2

    x0 = -0.1011
    y0 = 0.9563
    tl_x = x0 - 0.0001
    tl_y = y0 + 0.0001
    br_x = x0 + 0.0001
    br_y = y0 - 0.0001

    img = generate_mandelbrot(res_x, res_y, max_iter, tl_x, tl_y, br_x, br_y)
    IO.puts(byte_size(img))
    IO.puts(:os.system_time(:microsecond) - t)
    {:ok, vimg} = Vix.Vips.Image.new_from_binary(img, res_x, res_y, 3, :VIPS_FORMAT_UCHAR)
    Vix.Vips.Operation.pngsave(vimg, "priv/zigex.png", compression: 9)
  end
end
