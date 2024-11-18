# Mandelbrot Set with Zig and Numerical Elixir

## Introduction

Source:

- [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set)
- [Plotting algorithm](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set)


This repo is about visualising the orbits of points in the 2D-plane under a given map known the Julia or MAndelbrot sets.

We are looking whether the iterates stay bounded are not. When we associate a colour that reflects this stability, this gives rise to Mandelbrot images.

These images are therefor a colourful representation of where the sequence is stable and how fast does these sequences diverge.

<img with="600" alt="zoom detail" src="https://github.com/user-attachments/assets/f0e9dcaa-34b2-4789-97fd-895355a6a7a9">


This repo contains:
- a pur `Zig` computation
- two `Livebook` to explore the orbits of points and to zoom into the Mandelbrot set.

The Livebook proposes:
- a pur `Elixir` orbit explorer,
- a pur `Elixir` implementation  using Numerical Elixir with `EXLA` backend of the Mandelbrot set,
- an enhanced version where the heavy computations are made with embedding  `Zig` code thanks to the library `Zigler`.



## Orbit explorer

Given a complex number `c` and the polynomial `p_c(x)=x^2+c`, we compute the sequence of iterates:

```
p(0)=c
p(p(0))=p(c)=c^2+2
p(p(c)) = c^4+2c^3+c^2+c
...
```

The set of this sequence is the _orbit_ of the number `c` under the map `p`.

For example, for `c=1`, we have the orbit `O_1 = { 0, 1, 2, 5, 26,...}` but for `c=-1`, we have a cyclic orbit, `O_{-1} = {−1, 0, −1, 0,...}`.

The code below computes "orbits". You select a point and a little animation displays the orbit.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fndrean%2Fmandelbrot%2Fblob%2Fmain%2Flivebook%2Forbits.livemd)


<img width="639" alt="Screenshot 2024-11-14 at 19 22 38" src="https://github.com/user-attachments/assets/abe4a943-ac31-44db-85c4-906f14f958bd">


## Mandelbrot set explorer

### The algorithm

Given an image of size W x H in pixels,
- loop over 1..H rows,  `i`, and over 1..W columns, `j`
  - compute the coordinate `c` in the 2D-plane projection corresponding to the pixel `(i,j)`
  - compute the "escape" iterations `n`,
  - compute the RGB colours for this `n`,
  - append to your final array.

### A Livebook

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fndrean%2Fmandelbrot%2Fblob%2Fmain%2Flivebook%2Fmandelbrot.livemd)


You can explore the fractal by clicking into the 2D-plane. 

This happens thanks to `KinoJS.Live`.

We have a pur `Elixir` version that uses `Nx` with the `EXLA` backend, and another one that uses embedded `Zig` code for the heavy computations. The later is 3-4 magnitude faster.


![image](https://github.com/user-attachments/assets/e747dbc9-02b1-4fd3-9670-73218d632a5a)

## Details of the mandelbrot set

[Needs latex]

In fact, this set is contained in a disk 
$ D_2$ of radius 2. This does not mean that 
$ 0_c$ is bounded whenever 
$|c|\leq 2$ as seen above. Merely 
$0_c$ is certainly unbounded - the sequence of 
$z_n$ is divergent whenever 
$|c| > 2$.

We have a more precise criteria: whenever the absolute value $` |z_n| `$ is greater that 2, then the absolute values of the following iterates grow to infinity.

The **Mandelbrot set** $M$ is the set of numbers $c$ such that its sequence $O_c$ remains bounded (in absolute value). This means that $` | z_n (c) | < 2 `$ for any $` n `$.

When the sequence $` O_c `$ is _unbounded_, we associate to $c$ the first integer $N_c$ such that $` |z_N (c)| > 2 `$.

Since we have to stop the computations at one point, we set a limit $m$ to the number of iteration. Whenever we have $` |z_{n}|\leq 2 `$ when $n=m$, then point $` c `$ is declared _"mandelbrot stable"_.

When the sequence $O_c$ remains bounded, we associate to $` c `$ a value $` max `$.

So to each $` c `$ in the plane, we can associate an integer $n$, whether `null` or a value between 1 and $m$.
Furthermore, we decide to associate each integer $` n `$ a certain RGB colour.

With this map:

```math
c \mapsto n(c) \Leftrightarrow \mathrm{colour} = f\big(R(n),G(n),B(n)\big)
```

we are able to plot something.

By convention it is **black** when the orbit $O_c$ remains bounded.

When you represente the full Mandelbrot set, you can take advantage of the symmetry; indeed, if $c$ is bounded, so is its conjugate.

<hr/>

#### Math details:

Firstly consider some $` |c| \leq 2 `$ and suppose that for some $` N `$, we have $` |z_N|= 2+a `$ with $` a > 0 `$. Then:

```math
|z_{N+1}| = |z_N^2+c|\geq |z_N|^2 -|c| > 2+2a = |z_N|+a
```

so $` |z_{N+k}| \geq |z_N| +ka \to \infty `$ as $` k\to \infty `$.

Lastly, consider $|c| > 2$. Then for every $n$, we have $|z_n| > |c|$. So:

```math
|z_{n+1}| \geq |z_n|^2 -|c| \geq |z_n|^2-|z_n| = |z_n|(|z_n|-1) \geq |z_n|(|c|-1) > |z_n|
```

so the term grows to infinity and "escapes".

<hr/>

The _mandelbrot set_ $M$ is **compact**, as _closed_ and bounded (contained in the disk of radius 2).
It is also surprisingly _connected_.

> Fix an integer $n\geq 1$ and consider the set $M_n$ of complex numbers $c$ such that there absolute value at the rank $n$ is less than 2. In other words, $ M_n=\{c\in\mathbb{C}, \, |z_n(c)|\leq 2\} $. Then the complex numbers Mandelbrot-stable are precisely the numbers in all these $ M_n$, thus $M = \bigcap_n M_n$.
> We conclude by remarking that each $M_n$ is closed as a preimage of the closed set $ [0,2]$ by a continous function, and since $M$ is an intersection of closed sets (not necesserally countable), it is closed.
