# Mandelbrot Set

## Introduction

Source:

- [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set)
- [Plotting algorithm](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set)

<img width="613" alt="Screenshot 2024-11-05 at 19 35 32" src="https://github.com/user-attachments/assets/9eb71bec-b77e-4d04-bc88-bb86d19d6219">


Given a complex number $c$ and a polynomial $p_c(x)=x^2+c$, we compute the sequence of iterates:

$$O_c = \{ p_c(0), p_c(p_c(0)), p_c(p_c(p_c(0))),...\}$$

More precisely, given a number $c$, we compute the iterates (these are polynomials in $c$):

- $z_0 =c$
- $z_1= c^2+c$
- $z_2= z_1^2+c = c^4 + 2c^3 + c^2 + c$
- $z_3= z_2^2+c = c^8 + 4c^7 + 6c^6 + 6c^5 + 5c^4 + 2c^3 + c^2 + c$
  ...

The terms of sequence $O_c = \{z_n\;,\; n\geq 1\}$ is also called the orbit of $c$.
This sequence may or not remain bounded in absolute value.
For example, for $c=1$, we have the orbit $O_1 = \{ 0, 1, 2, 5, 26,\dots\}$ but for $c=-1$, we have a cyclic orbit, $O_{-1} = \{−1, 0, −1, 0,\dots\}$.

The goal here is to attribute an interation number $n$ to each complex $c$. This iteration number represents the indice of the orbit where either $z_n$ leaves the disk of radius 2 or stays in it after say $m=100$ iterations.

With this $n$, we will associate a colour R,G,B to visualise the stability.

Then, from a given canvas of say 1000 x 1000 pixels, we associate each pixel with a point $c$ in hte complex plan. We will then be able to produce a colourful image representing this Mandelbrot set.

## First evaluation of orbits of points

We firstly evaluated in a Livebook how stable the orbits are for some points.

With this code, we see that running 100 iterates takes around 0.1ms.
We see that Elixir would take for a coarse grained image of 1000 x 1000 a minimum of 100s.

Zig might bit indeed a better fit.

<details><summary>Orbits</summary>

```elixir
Mix.install(
  [
    {:kino_vega_lite, "~> 0.1.11"},
    {:complex, "~> 0.5.0"}
  ]
)


defmodule Mandelbrot do
  def p(z,c) do
    Complex.multiply(z,z) |> Complex.add(c)
  end

  def orb(1,c), do: c
  def orb(n,c) do
    Enum.reduce_while(1..n, [c], fn i, acc ->
      case acc do
       [c] ->
          %{re: re, im: im} = c
          if re*re+im*im  > 4 do
            {:halt, {i,acc}}
          else
            {:cont,[p(c,c) | acc]}
          end
        [t |_ ] = acc ->
          %{re: re, im: im} = t
          cond do
            re*re+im*im  > 10 ->
              IO.puts "escapes"
              {:halt, {i, acc}}
            i == n-1 ->
              IO.puts "stable until"
              {:halt, {i, acc}}
            true ->
              {:cont, [p(t,c) | acc]}
          end
      end
    end)
  end
end

defmodule Chart do
  def data(n,c) do
    {nb, points} = Mand.orb(n,c)
     points =  Enum.map(points, fn %{re: re, im: im} -> [re,im] end)

    # you can't plot more points than you have
    n = if nb<n, do: nb, else: n

    for i <- 0..n-1 do
        %{"x" => Enum.at(Enum.at(points, i), 0), "y" => Enum.at(Enum.at(points, i), 1)}
    end
  end
end
```

</details>
<br/>

## Details of the mandelbrot set

In fact, this set is contained in a disk $D_2$ of radius 2. This does not mean that $0_c$ is bounded whenever $|c|\leq 2$ as seen above. Merely $0_c$ is certainly unbounded - the sequence of $z_n$ is divergent whenever $|c| > 2$.

We have a more precise criteria: whenever the absolute value $|z_n|$ is greater that 2, then the absolute values of the following iterates grow to infinity.

The **Mandelbrot set** $M$ is the set of numbers $c$ such that its sequence $O_c$ remains bounded (in absolute value). This means that $| z_n (c) | < 2$ for any $n$.

When the sequence $O_c$ is _unbounded_, we associate to $c$ the first integer $N_c$ such that $|z_N (c)| > 2$.

Since we have to stop the computations at one point, we set a limit $m$ to the number of iteration. Whenever we have $|z_{n}|\leq 2$ when $n=m$, then point $c$ is declared _"mandelbrot stable"_.

When the sequence $O_c$ remains bounded, we associate to $c$ a value $n_{\infty}$. For convenience, we set it in Zig to `null`.

So to each $c$ in the plane, we can associate an integer $n$, whether `null` or a value between 1 and $m$.
Furthermore, we decide to associate each integer $n$ a certain RGB colour.

With this map:

$$c \mapsto n(c) \Leftrightarrow \mathrm{colour} = f\big(R(n),G(n),B(n)\big)$$

we are able to plot something.

By convention it is **black** for `null`, when the orbit $O_c$ remains bounded.

Then we will try to express colours to represent how quickly the sequence at that point escapes. We use an easy linear scale.
We decide for example to associate a warm and vibrant colour to small $n_c$ values - where the sequence $M_c$ quickly diverges - and associate a darker colour when the number $n_c$ increases (th sequence $ M_c$ is more longer "bounded").

These images are therefor a colourful representation of where the sequence is stable and how fast does these sequences diverge.

To render such an image, we must consider how many pixels a certain region of the complex plan contains.

We can for example consider a very course grained 100x200 pixels image to represent a square region centered at (0,0) of length 2.

A finer grained picture with 4090x2160 pixels can zoom into details of a square region of length 0.001 centered at (0.38755, 0.2005).

In order to save computations, we firstly note that the image is symetric upon the X axis. This is because if $c$ is bounded, so is it conjugate $\bar{c}$.

Then, we can parallelise the computations - associating a colour to each point of the plan - since they are all independant.

## The algorithm:

- instantiate a slice pixels of length say 1_000 x 1_000 x 3 = 3_000_000 bytes (u8)
- loop over 1..1000 rows, `i`
  - loop over 1..1_000 columns, `j`
  - compute the coordinate c in the complex plan corresponding to the pixel `(i,j)`
  - compute the iterations `n`, the length of the orbit of c,
  - compute the RGB colours for this n: it is a length 3 array `col= [ R(n), G(n), B(n) ]`
  - append to pixels at position `( i + j ) * 3` to this array.

<details><summary>Fun math facts</summary>

Firstly consider some $|c| \leq 2$ and suppose that for some $N$, we have $|z_N|= 2+a$ with $a > 0$. Then:

$$|z_{N+1}| = |z_N^2+c|\geq |z_N|^2 -|c| > 2+2a = |z_N|+a$$

so $|z_{N+k}| \geq |z_N| +ka \to \infty$ as $k\to \infty$.

Lastly, consider $|c| > 2$. Then for every $n$, we have $|z_n| > |c|$. So:

$$|z_{n+1}| \geq |z_n|^2 -|c| \geq |z_n|^2-|z_n| = |z_n|(|z_n|-1) \geq |z_n|(|c|-1) > |z_n|$$

so the term grows to infinity and "escapes".

<br/>

The _mandelbrot set_ $M$ is **compact**, as _closed_ and bounded (contained in the disk of radius 2).
It is also surprisingly _connected_.

> Fix an integer $n\geq 1$ and consider the set $M_n$ of complex numbers $c$ such that there absolute value at the rank $n$ is less than 2. In other words, $M_n=\{c\in\mathbb{C}, \, |z_n(c)|\leq 2\}$. Then the complex numbers Mandelbrot-stable are precisely the numbers in all these $ M_n$, thus $M = \bigcap_n M_n$.
> We conclude by remarking that each $M_n$ is closed as a preimage of the closed set $ [0,2]$ by a continous function, and since $M$ is an intersection of closed sets (not necesserally countable), it is closed.

</details>
<br/>
