# Mandelbrot Set with Zig and Numerical Elixir

## Introduction

Source:

- [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set)
- [Plotting algorithm](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set)

<img width="613" alt="Screenshot 2024-11-05 at 19 35 32" src="https://github.com/user-attachments/assets/9eb71bec-b77e-4d04-bc88-bb86d19d6219">



Given a complex number `c` and the polynomial `p_c(x)=x^2+c`, we compute the sequence of iterates:

```
p(0)=c
p(p(0))=p(c)=c^2+2
p(p(c)) = c^4+2c^3+c^2+c
...
```

The set of this sequence is the _orbit_ of the number `c` under the map `p`.

The study of the orbits of numbers in terms of whether they are bounded are not, gives rise to Mandelbrot images like the one above when we associate a colour to each point.
These images are therefor a colourful representation of where the sequence is stable and how fast does these sequences diverge.

This repo contains a pur `Zig` computation and a pur `Elixir` one using Numerical Elixir. The Elixir code can be run in a Livebook. The Elixir code can also run embedded Zig code with the library `Zigler`.

## First evaluation of orbits of points

We firstly evaluated in a Livebook how stable the orbits are for some points.

For example, for `c=1`, we have the orbit `O_1 = { 0, 1, 2, 5, 26,...}` but for `c=-1`, we have a cyclic orbit, `O_{-1} = {−1, 0, −1, 0,...}`.

The code below is in the Livebook "orbits".

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fndrean%2Fmandelbrot%2Fblob%2Fmain%2Flivebook%2Forbits.livemd)

<details><summary>Code for visualizing orbits in Elixir</summary>
  
# Mandelbrot orbits

```elixir
Mix.install(
  [
    {:nx, "~> 0.9.1"},
    {:exla, "~> 0.9.1"},
    {:kino_vega_lite, "~> 0.1.11"},
    {:complex, "~> 0.5.0"}
  ],
  config: [nx: [default_backend: EXLA.Backend]]
)
Nx.Defn.global_default_options(compiler: EXLA, client: :host)
```

## Nx computations

```elixir
defmodule Ncx do
  import Nx.Defn

  defn i(), do: Nx.Constants.i()
  # primitive to build a complex scalar tensor
  defn new(x,y), do: x + i() * y
  # square norm
  defn sq_norm(z), do: Nx.conjugate(z) |> Nx.dot(z) |> Nx.real()
end
```

## Orbit number

```elixir
defmodule Orbit do
  import Nx.Defn

  defn p(z,c), do: z*z + c
  
  defn calc(c, opts) do
    n = opts[:n]

    while { i=1, _nb=0, t=Nx.broadcast(c,{n}),c }, Nx.less(i,n) do
      cond do
        Nx.greater(Ncx.sq_norm(t[i-1]), 4) ->
          {n, i-1, t, c}
        true ->
        { i + 1, i, Nx.indexed_put(t, Nx.stack([i]), p(t[i-1], c)),c }
      end
    end
  end
end



```

## Plotting orbits

```elixir
defmodule Plot do
  def new(cx,cy, imax) do
    c = Ncx.new(cx,cy)
    {_, nb, t, _} = Orbit.calc(c, n: imax)   

    {data_x,data_y} = Nx.slice(t, [0], [Nx.to_number(nb)])
    |> Nx.to_list()
    |> Enum.map(fn z -> {Complex.real(z), Complex.imag(z)} end)
    |> Enum.unzip()

    {nb, %{x: data_x, y: data_y}, %{x: [cx], y: [cy]}}
  end
end

```

## Unstable point

```elixir
# Unstable point
cx = 0.35; 
cy = 0.38

{nb, data, data1} = Plot.new(cx, cy, 100)
"Point [#{cx},#{cy}] is unstable. It escapes after #{Nx.to_number(nb)} iterations"
```

```elixir
VegaLite.new(width: 600, height: 600)
|> VegaLite.layers([
  VegaLite.new()
  |> VegaLite.data_from_values(data, only: ["x", "y"])
  |> VegaLite.mark(:point)
  |> VegaLite.encode_field(:x, "x", type: :quantitative)
  |> VegaLite.encode_field(:y, "y", type: :quantitative),
  VegaLite.new()
  |> VegaLite.data_from_values(data1, only: ["x", "y"])
  |> VegaLite.mark(:point, tooltip: true, color: "red")
  |> VegaLite.encode_field(:x, "x", type: :quantitative)
  |> VegaLite.encode_field(:y, "y", type: :quantitative)
])
```

## Example Stable point

```elixir
cx = 0.3; 
cy = 0.3

{nb, data, data1} = Plot.new(cx, cy, 100)
"Point [#{cx},#{cy}] is stable. It says bounded after #{Nx.to_number(nb)} iterations"
```

```elixir
VegaLite.new(width: 600, height: 600)
|> VegaLite.layers([
  VegaLite.new()
  |> VegaLite.data_from_values(data, only: ["x", "y"])
  |> VegaLite.mark(:point, color: "green")
  |> VegaLite.encode_field(:x, "x", type: :quantitative)
  |> VegaLite.encode_field(:y, "y", type: :quantitative),
  VegaLite.new()
  |> VegaLite.data_from_values(data1, only: ["x", "y"])
  |> VegaLite.mark(:point, color: "blue")
  |> VegaLite.encode_field(:x, "x", type: :quantitative)
  |> VegaLite.encode_field(:y, "y", type: :quantitative),
])


```

</details>
<br/>

This code helps to visualize the orbit for the stable point (0.3, 0.3)

![image](https://github.com/user-attachments/assets/baca9f97-e9d2-4bb0-8ad3-3153504a7944)

The orbit of the  unstable point (0.35, 0.38) which escapes after 49 iterations.

![image](https://github.com/user-attachments/assets/56403cd1-870a-4d3c-8ad3-33527eb04650)


## The algorithm

- instantiate a slice pixels of length say W x H x 3
- loop over 1..H rows, `i`
  - loop over 1..W columns, `j`
  - compute the coordinate c in the complex plan corresponding to the pixel `(i,j)`
  - compute the "escape" iterations `n`,
  - compute the RGB colours for this n: it is a length 3 array `col= [ R(n), G(n), B(n) ]`
  - append to pixels at position `( i + j ) * 3` to this array.

## Livebook

This can be run in a Livebook.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fndrean%2Fmandelbrot%2Fblob%2Fmain%2Flivebook%2Fmandelbrot.livemd)


![image](https://github.com/user-attachments/assets/e747dbc9-02b1-4fd3-9670-73218d632a5a)

<details><summary>Livebook with pur Elixir and embedded Zig</summary>

```elixir
Mix.install(
  [
    {:nx, "~> 0.9.1"},
    {:exla, "~> 0.9.1"},
    {:kino, "~> 0.14.2"},
    {:zigler, "~> 0.13.3"},
  ],
  config: [nx: [default_backend: EXLA.Backend]]
)

Nx.Defn.global_default_options(compiler: EXLA, client: :host)
```

## Introduction

We want to produce an image that represents the beautiful **Mandelbrot set**

Source: <https://en.wikipedia.org/wiki/Mandelbrot_set>

It is surprinsigly simple to do this in a `Livebook` and with `Nx`, the Numercial `Elixir`.

> We also propose to run the equivalent code in `Zig` in `Livebook` if you want extra speed. This happens thanks to the [Zigler](https://hexdocs.pm/zigler/Zig.html) library. The `Zig` code returns a binary that `Nx` is able to consume and `Kino` to display.

In a "Mandlebrot image", each pixel has a colour repesenting how _fast_ the _underlying point_ _"escapes"_ when calculating its _iterates_ under a certain function.

#### What is an underlying point?

A pixel has some coordinates `[i,j]`. For example, in a 1024 × 768 image (WIDTH x HEIGHT), the row number varies from from 0 to 1023 and column number from 0 to 767.

We transform these couples of integers `(i,j)` into a point in real numbers 2D plane. We "quantitize" the complex plane.

Here, the 2D "real" plan is defined by the upper left corner, say `(-2,1)`, and bottom right corner, say `(1,-1)`.

We "project" the coordinates into a real plane. For example, the pixel `(0,0)` becomes `(-2,1)` and the pixel `(999, 1999)` becomes `(1,-1)`.

#### Which function? What is iterating?

We will iterate the function: `f(x) = x*x +c` where `c` is a given number and `x` the variable.

We start with `z0 = f(0) = c`, then `z1 = f(z0) = z0 * z0 + c` then `z2 = f(z1) = z1 * z1 + c` etc...

Let's take an example. The module below calculates the iterations `x(n) = f(x(n-1))` by a simple recursion.

The sets of these iterates of `c` is called its _orbit_ .

```elixir
defmodule Simple do
  def p(x,c), do: x**2 + c

  # initial value
  def iterate(1,c), do: c

  # the n-th step
  def iterate(n,c), do: p(iterate(n-1, c), c)
end
```

We calculate the first elements of its orbit and evaluate how does the point `c=1` behaves. It looks like it will diverge to infinity.

```elixir
c = 1
{ c,
  Simple.iterate(1,c), Simple.iterate(2,c), Simple.iterate(3,c), Simple.iterate(4,c),
}
```

On the other side, the point `c=-1` seems well bahaved: the orbit has only two values, 0 and - 1, and is periodic.

```elixir
c = -1

{ c,
  Simple.iterate(1,c), Simple.iterate(2,c), Simple.iterate(3,c), Simple.iterate(4,c),
}
```

In the examples above, we took a simple "real" number.

For the Mandelbrot set, we use the complex repesentation of a point: `(x,y) -> x + y*i` where `i` is the imaginary number (`i * i = -1`).

So, each pixel `(i,j)` is mapped to a complex number `c = projection(i,j)`, and we want to evaluate how do the iterates of `c` behave under the iteration `z(n+1) = z(n)*z(n) + c` with `z0 = c`.

<!-- livebook:{"break_markdown":true} -->

#### Iteration number?

We are interested by assigning a **iteration number** to each `c`.

The number of iterations that we compute is bounded by a value `max_iter`. We can fix it to say 50.

If the orbit of `c` remains bounded, we assign an _iteration number_ to `max_iter`.

If it escapes, meaning one iterate has a norm greater than 2, then we calculate the _first index_ such that the iterate norm is greater than 2 (in absolute value as a complex, or its norm as a point).

## Complex calculus interface

We will use two types of functions:

- `Elixir` functions using `def`
- `Nx` functions using `defn`; these use a special backend (EXLA with CPU or GPU if any)

The points of the 2D plane will be represented as complex numbers as the Mandelbrot map works with complex numbers.

The function `z(n+1) = z(n) * z(n) + c` takes a complex number and returns a complex number.

Below is a helper module to work with complex number in numerical Elixir.

> We use numerical functions, declared with `defn`. All the arguments are treated as _tensors_ .

```elixir
defmodule Ncx do
  import Nx.Defn

  defn i(), do: Nx.Constants.i()

  # primitive to build a complex scalar tensor
  defn new(x,y), do: x + i() * y

  # square norm
  defn sq_norm(z), do: Nx.conjugate(z) |> Nx.dot(z) |> Nx.real()
end
```

## Algorithm

Source: <https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set>

Input: image dimensions (eg 1000 x 1500), max iteration (eg 50)

For each pixel:

- compute its "complex coordinates"
- compute the iteration number
- compute a colour

Sum-up and draw from the final tensor with `Kino`.

## Orbit and iteration number

The module computes the **iteration number** for a given input `c`.

If `|c|>2`, then this point is unstable. Otherwise, we have to compute for each point whever it stays bounded or not. If it is bounded, we get `max_iter`, otherwise a lower value.

It is also using numerical functions via `defn`.

> Note how we loop using the `Nx` versions of `while` and the double condition managed by`Nx.logical_and`, and also the `Nx` version of `cond`. These macros delegate the code to the backend for performance.

```elixir
defmodule Orbit do
  import Nx.Defn

  defn poly(z,c), do: z*z + c

  defn number(c,max_iter) do
    condition = (Nx.real(c) +1) ** 2 + (Nx.imag(c)**2)
    cond do
      # points in first cardioid are all stable. Save on iterations
      Nx.less(condition, 0.0625) ->
        max_iter
      # these points are unbounded whenever the norm is > 2
      Nx.greater(Ncx.sq_norm(c), 4) ->
        0
      # we have to evaluate each point as it can be or not bounded in the disk 2
      1 ->
          {_, _, j} =
            while {z=c, c, i=max_iter}, Nx.logical_and(Nx.greater(i,1), Nx.less(Ncx.sq_norm(z), 4)) do
                {poly(z,c), c,i-1}
            end
          max_iter - j
    end
  end
end
```

**Examples**:

```elixir
st  = Ncx.new(0.2, 0.2)
dv1 = Ncx.new(0.4, 0.4)
dv2 = Ncx.new(0.3, 0.6)
dv3 = Ncx.new(2.0,2.0)

iter_max = 100

iter_dv1 = Orbit.number(dv1, iter_max) #<- we should find 8 iterations before z_n escapes from the disk 2
iter_dv2 = Orbit.number(dv2, iter_max) #<- we should find 14 iterations before z_n escapes from the disk 2
iter_dv3 = Orbit.number(dv3, iter_max)
iter_st  = Orbit.number(st, iter_max) #<- this point is stable and the loop reaches n interations.

%{
  "unstable/2:    #{Nx.to_number(dv2)}" => iter_dv2 |> Nx.to_number(),
  "unstable/1:    #{Nx.to_number(dv1)}" => iter_dv1 |> Nx.to_number(),
  "out_of_disk2:  #{Nx.to_number(dv3)}" => iter_dv3 |> Nx.to_number(),
  "stable:        #{Nx.to_number(st)}" => iter_st |> Nx.to_number(),
}
```

## Colour calculation

Each **iteration number** is an integer $n$. We want to associate a colour $[r(n),g(n),b(n)]$.

This will help us to visualise which point of the complex plane is stable, and if not how fast it escapes. The colour gives a visual impression of this "escaping speed".

> We stay under the `Defn` goodness. Note the type casting `Nx.type_as`.

```elixir
defmodule Colour do
  import Nx.Defn

  defn normalize(n, max_iter) do
    n / max_iter
  end

  defn rgb(n) do
    cond do
      Nx.equal(n, 0) ->
        Nx.stack([255, 255, 128]) |> Nx.as_type(:u8)
      Nx.less(n, 0.5) ->
        s = n * 2
        r = 255 * (1 - s)
        g = 255 * (1 - s/2)
        b = 127 + 128 * s
        Nx.stack([r, g, b]) |> Nx.as_type(:u8)
      true ->
        s = 2 * n - 1
        r = 0
        g = 127 * (1 - s/2)
        b = 255 * (1 - s)
         Nx.stack([r, g, b]) |> Nx.as_type(:u8)
    end
  end
end
```

```elixir
n = 0; max_iter = 100

[0, 49, 51, 100]
|> Enum.map(fn n ->  Colour.normalize(n, max_iter) |> Colour.rgb() end)

```

## Pixel to complex plan

We quantitize the complex plane by mapping pixels to complex numbers.

Given a granularity of say 1M pixels (1000 x 1000 pixels), we map each pixel to a point in the complex plan by calculating the coordinates.

This is what the module below does.

```elixir
defmodule Pixel do
  import Nx.Defn

  defn map(index, {h,w}, {top_left_x, top_left_y, bottom_right_x,bottom_right_y}) do

    scale_x = Nx.divide(bottom_right_x-top_left_x, w-1)
    scale_y = Nx.divide(bottom_right_y-top_left_y, h-1)

    Ncx.new(
      top_left_x + Nx.dot(index[1],scale_x),
      top_left_y + Nx.dot(index[0], scale_y)
    )
  end
end
```

## Computing the Mandelbrot set

For each pixel, we compute its complex coordinates. We then compute its iteration
number. With this number, we compute a colour.

**Example**:

```elixir
dim = {100,100}
iter_max = 100
top_left_x = -2; top_left_y = 1.2; bottom_right_x = 0.6; bottom_right_y = - 1.2;
defining_points = {top_left_x, top_left_y, bottom_right_x, bottom_right_y}

p = Nx.tensor([30,1])
c_i_j = Pixel.map(p,dim, defining_points)
n_i_j = Orbit.number(c_i_j, iter_max)
nm_i_j = Colour.normalize(n_i_j, iter_max)
{Nx.to_number(n_i_j), Colour.rgb(nm_i_j)} |> dbg()

p = Nx.tensor([40,70])
c_i_j = Pixel.map(p,dim, defining_points)
n_i_j = Orbit.number(c_i_j, iter_max)
nm_i_j = Colour.normalize(n_i_j, iter_max)
{Nx.to_number(n_i_j), Colour.rgb(nm_i_j)} |> dbg()

p = Nx.tensor([5,20])
c_i_j = Pixel.map(p,dim, defining_points)
n_i_j = Orbit.number(c_i_j, iter_max)
nm_i_j = Colour.normalize(n_i_j, iter_max)
{Nx.to_number(n_i_j), Colour.rgb(nm_i_j)}

```

**The final module**

We build the cross product of the `(i,j)` to build a tensor representation
of the indices: each couple `(i,j)` represents the pixel of the image.

For each point, we compute its iterations number, and then a colour.

We then reassamble the tensor into the desired format for `Kino` to consume it and display.

> Note that to pass arguments into a `defn` function that you want to be
> treated as arguments, you use a keyword list `opts`.

```elixir
defmodule Mandelbrot do
  import Nx.Defn

  defn compute(opts) do
    top_left_x = -2; top_left_y = 1.2; bottom_right_x = 0.6; bottom_right_y = - 1.2;
    defining_points = {top_left_x, top_left_y, bottom_right_x, bottom_right_y}

    h = opts[:h]
    w = opts[:w]
    max_iter = opts[:max_iter]

    # build the tensor [[0,0],, ...[0,m], [1,1]...[n,m]]. Thks to PValente
    iota_rows = Nx.iota({h}, type: :u16) |> Nx.vectorize(:rows)
    iota_cols = Nx.iota({w}, type: :u16) |> Nx.vectorize(:cols)
    cross_product = Nx.stack([iota_rows, iota_cols])

    Pixel.map(cross_product,{h,w}, defining_points)
      |> Orbit.number(max_iter)
      |> Colour.normalize(max_iter)
      |> Colour.rgb()
      |> Nx.devectorize()
      |> Nx.reshape({h, w, 3})
      |> Nx.as_type(:u8)
  end
end

```

Depending on your machine, the computation below can be lengthy. On mine, it took 400s to draw 1M pixels (a 1000 x 1000 image).
If you want to simply evaluate, set `h = w = 400`.

```elixir
h = w = 400;
Mandelbrot.compute(h: h, w: w, max_iter: 100)
|> Kino.Image.new()
```

## Parallelise it with async_stream

When the resolution of the image increases, it is interesting to parallelize the computations.

We divide the image in horizontal bands, as much as the number of CPU cores on the machine.

We use `async_stream` to parallelize the computations on the cores of the machine. This is natively implemented in the BEAM, the VM that runs this code.

> This is worth only if the size of the image is large enough as this comes with non negligeable overhead.

We also set `ordered: true` as we need to sum-up the results in an ordered manner.

> Another possible optimisation is to remark that the image is symmetric. You can compute half of the image (redefine `h` to be `h-rem(h, cpus*2)` but you would need to be able to reverse a tensor.

```elixir
defmodule StreamMandelbrot do
  import Nx.Defn

    @doc"""
    Example: 42 rows, 8 cpus
    42 rows = 8cpus * 5 + 2
    We run 8 threads consuming 5 rows each
    We just ignore the last 2 rows.
    """
    def run(%{h: h, w: w} = opts) do
      cpus = :erlang.system_info(:logical_processors_available)
      # we eliminate a few rows from the final image, 8 at most.
      h = h - rem(h,cpus)
      rows_per_cpu = div(h, cpus)

      Task.async_stream(0..cpus-1, fn cpu_count ->
          # we shift the start index by the number of rows already consummed
          iota_rows = Nx.iota({rows_per_cpu}, type: :u16) |> Nx.add(cpu_count * rows_per_cpu)|> Nx.vectorize(:rows)
          # full width
          iota_cols = Nx.iota({w}, type: :u16) |> Nx.vectorize(:cols)
          cross_product = Nx.stack([iota_rows, iota_cols])
          Nx.Defn.jit_apply(fn t ->
            compute(t, opts) end, [cross_product])
          end,
          timeout: :infinity, ordered: true
      )
      |> Enum.map(fn {:ok, t} -> t end) #&elem(&1, 1)
      |> Nx.stack()
      |> Nx.reshape({h,w,3})
  end



  defn compute(cross_product, %{h: h, w: w, max_iter: max_iter}) do
    top_left_x = -2; top_left_y = 1.2; bottom_right_x = 0.6; bottom_right_y = -1.2;
    defining_points = {top_left_x, top_left_y, bottom_right_x, bottom_right_y}

    Pixel.map(cross_product,{h,w}, defining_points)
    |> Orbit.number(max_iter)
    |> Colour.normalize(max_iter)
    |> Colour.rgb()
    |> Nx.devectorize()
    |> Nx.as_type(:u8)
  end
end
```

When we run the code, we have much faster results. On my machine, it took 44s to draw a 1M pixels image. We get the expected performance boost.

```elixir
h= w = 400;

StreamMandelbrot.run( %{h: h, w: w, max_iter: 100})
|> Kino.Image.new()
```

## Run embedded Zig code

If we still need or want extra speed, we can also embed `Zig` code in `Elixir` within a Livebook.

`Zigler` offers a [remarkable documentation](https://hexdocs.pm/zigler/readme.html#installation-elixir).

You may to have `Zig` installed on your machine.

Run:

```
mix zig.get
```

In the `Livebook`, we add the dependencies (in the first cell):

<!-- livebook:{"force_markdown":true} -->

```elixir
Mix.install([{:zigler, "~> 0.13.3"},{:zig_get, "~> 0.13.1"},])
```

With the `Zigler`, we can even inline Zig code.

The code below runs the same algorithm and runs OS threads for concurrency.

```elixir
defmodule Zigit do
  use Zig, otp_app: :zigler,
    nifs: [..., generate_mandelbrot: [:threaded]]
    # release_mode: :fast

  ~Z"""
    const beam = @import("beam");
    const std = @import("std");
    const Cx = std.math.Complex(f64);

    const topLeft = Cx{ .re = -2.1, .im = 1.2 };
    const bottomRight = Cx{ .re = 0.6, .im = -1.2 };
    const w = bottomRight.re - topLeft.re;
    const h = bottomRight.im - topLeft.im;

    const Context = struct {res_x: usize, res_y: usize, imax: usize};

    /// nif: generate_mandelbrot/3 Threaded
    pub fn generate_mandelbrot(res_x: usize, res_y: usize, max_iter: usize) !beam.term {
        const pixels = try beam.allocator.alloc(u8, res_x * res_y * 3);
        defer beam.allocator.free(pixels);

        const resolution = Context{ .res_x = res_x, .res_y = res_y, .imax = max_iter };

        const res = try createBands(pixels, resolution);
        return beam.make(res, .{ .as = .binary });
    }

    // <--- threaded version
    fn createBands(pixels: []u8, ctx: Context) ![]u8 {
        const cpus = try std.Thread.getCpuCount();
        var threads = try beam.allocator.alloc(std.Thread, cpus);
        defer beam.allocator.free(threads);

        // half of the total rows
        const rows_to_process = ctx.res_y / 2 + ctx.res_y % 2;
        // one band is one count of cpus
        // const nb_rows_per_band = rows_to_process / cpus + rows_to_process % cpus;
        const rows_per_band = (rows_to_process + cpus - 1) / cpus;

        for (0..cpus) |cpu_count| {
            const start_row = cpu_count * rows_per_band;

            // Stop if there are no rows to process
            if (start_row >= rows_to_process) break;

            const end_row = @min(start_row + rows_per_band, rows_to_process);
            const args = .{ ctx, pixels, start_row, end_row };
            threads[cpu_count] = try std.Thread.spawn(.{}, processRows, args);
        }
        for (threads[0..cpus]) |thread| {
            thread.join();
        }

        return pixels;
    }

    fn processRows(ctx: Context, pixels: []u8, start_row: usize, end_row: usize) void {
        for (start_row..end_row) |current_row| {
            processRow(ctx, pixels, current_row);
        }
    }

    fn processRow(ctx: Context, pixels: []u8, row_id: usize) void {
        // Calculate the symmetric row
        const sym_row_id = ctx.res_y - 1 - row_id;

        if (row_id <= sym_row_id) {
            // loop over columns
            for (0..ctx.res_x) |col_id| {
                const c = mapPixel(.{ @as(usize, @intCast(row_id)), @as(usize, @intCast(col_id)) }, ctx);
                const iter = iterationNumber(c, ctx.imax);
                const colour = createRgb(iter, ctx.imax);

                const p_idx = (row_id * ctx.res_x + col_id) * 3;
                pixels[p_idx + 0] = colour[0];
                pixels[p_idx + 1] = colour[1];
                pixels[p_idx + 2] = colour[2];

                // Process the symmetric row (if it's different from current row)
                if (row_id != sym_row_id) {
                    const sym_p_idx = (sym_row_id * ctx.res_x + col_id) * 3;
                    pixels[sym_p_idx + 0] = colour[0];
                    pixels[sym_p_idx + 1] = colour[1];
                    pixels[sym_p_idx + 2] = colour[2];
                }
            }
        }
    }

    fn mapPixel(pixel: [2]usize, ctx: Context) Cx {
        const px_width = ctx.res_x - 1;
        const px_height = ctx.res_y - 1;
        const scale_x = w / @as(f64, @floatFromInt(px_width));
        const scale_y = h / @as(f64, @floatFromInt(px_height));

        const re = topLeft.re + scale_x * @as(f64, @floatFromInt(pixel[1]));
        const im = topLeft.im + scale_y * @as(f64, @floatFromInt(pixel[0]));
        return Cx{ .re = re, .im = im };
    }

    fn iterationNumber(c: Cx, imax: usize) ?usize {
        if (c.re > 0.6 or c.re < -2.1) return 0;
        if (c.im > 1.2 or c.im < -1.2) return 0;

        // first cardiod
        if ((c.re + 1) * (c.re + 1) + c.im * c.im < 0.0625) return null;

        var z = Cx{ .re = 0.0, .im = 0.0 };
        for (0..imax) |j| {
            if (sqnorm(z) > 4) return j;
            z = Cx.mul(z, z).add(c);
        }
        return null;
    }

    fn sqnorm(z: Cx) f64 {
        return z.re * z.re + z.im * z.im;
    }

    fn createRgb(iter: ?usize, imax: usize) [3]u8 {
        // If it didn't escape, return black
        if (iter == null) return [_]u8{ 0, 0, 0 };

        // Normalize time to [0,1[ now that we know it isn't "null"
        const normalized = @as(f64, @floatFromInt(iter.?)) / @as(f64, @floatFromInt(imax));

        if (normalized < 0.5) {
            const scaled = normalized * 2;
            return [_]u8{ @as(u8, @intFromFloat(255 * (1 - scaled))), @as(u8, @intFromFloat(255.0 * (1 - scaled / 2))), @as(u8, @intFromFloat(127 + 128 * scaled)) };
        } else {
            const scaled = (normalized - 0.5) * 2.0;
            return [_]u8{ 0, @as(u8, @intFromFloat(127 * (1 - scaled / 2))), @as(u8, @intFromFloat(255 * (1 - scaled))) };
        }
    }

  """
end
```

We run the Zig code. It returns a binary that we are able to consume with `Nx` and display the image.

To draw an image of 1M pixels, it takes a few milliseconds. Feels like magic.

```elixir
h = w = 1_000
max_iter = 100;

Zigit.generate_mandelbrot(h, w, max_iter)
|> Nx.from_binary(:u8)
|> Nx.reshape({h, w, 3})
|> Kino.Image.new()
```

</details>
<br/>

## Details of the mandelbrot set

[Needs latex]

In fact, this set is contained in a disk $D_2$ of radius 2. This does not mean that $0_c$ is bounded whenever $|c|\leq 2$ as seen above. Merely $0_c$ is certainly unbounded - the sequence of $z_n$ is divergent whenever $|c| > 2$.

We have a more precise criteria: whenever the absolute value $|z_n|$ is greater that 2, then the absolute values of the following iterates grow to infinity.

The **Mandelbrot set** $M$ is the set of numbers $c$ such that its sequence $O_c$ remains bounded (in absolute value). This means that $| z_n (c) | < 2$ for any $n$.

When the sequence $O_c$ is _unbounded_, we associate to $c$ the first integer $N_c$ such that $|z_N (c)| > 2$.

Since we have to stop the computations at one point, we set a limit $m$ to the number of iteration. Whenever we have $|z_{n}|\leq 2$ when $n=m$, then point $c$ is declared _"mandelbrot stable"_.

When the sequence $O_c$ remains bounded, we associate to $c$ a value $n_{\infty}$.

So to each $c$ in the plane, we can associate an integer $n$, whether `null` or a value between 1 and $m$.
Furthermore, we decide to associate each integer $n$ a certain RGB colour.

With this map:

$$c \mapsto n(c) \Leftrightarrow \mathrm{colour} = f\big(R(n),G(n),B(n)\big)$$

we are able to plot something.

By convention it is **black** when the orbit $O_c$ remains bounded.

When you represente the full Mandelbrot set, you can take advantage of the symmetry; indeed, if $c$ is bounded, so is its conjugate.

<hr/>

#### Math details:

Firstly consider some $|c| \leq 2$ and suppose that for some $N$, we have $|z_N|= 2+a$ with $a > 0$. Then:

$$|z_{N+1}| = |z_N^2+c|\geq |z_N|^2 -|c| > 2+2a = |z_N|+a$$

so $|z_{N+k}| \geq |z_N| +ka \to \infty$ as $k\to \infty$.

Lastly, consider $|c| > 2$. Then for every $n$, we have $|z_n| > |c|$. So:

$$|z_{n+1}| \geq |z_n|^2 -|c| \geq |z_n|^2-|z_n| = |z_n|(|z_n|-1) \geq |z_n|(|c|-1) > |z_n|$$

so the term grows to infinity and "escapes".

<hr/>

The _mandelbrot set_ $M$ is **compact**, as _closed_ and bounded (contained in the disk of radius 2).
It is also surprisingly _connected_.

> Fix an integer $n\geq 1$ and consider the set $M_n$ of complex numbers $c$ such that there absolute value at the rank $n$ is less than 2. In other words, $M_n=\{c\in\mathbb{C}, \, |z_n(c)|\leq 2\}$. Then the complex numbers Mandelbrot-stable are precisely the numbers in all these $ M_n$, thus $M = \bigcap_n M_n$.
> We conclude by remarking that each $M_n$ is closed as a preimage of the closed set $ [0,2]$ by a continous function, and since $M$ is an intersection of closed sets (not necesserally countable), it is closed.
