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

The code below computes "orbits". You select a point and a little animation displays the orbit.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fndrean%2Fmandelbrot%2Fblob%2Fmain%2Flivebook%2Forbits.livemd)


<img width="639" alt="Screenshot 2024-11-14 at 19 22 38" src="https://github.com/user-attachments/assets/abe4a943-ac31-44db-85c4-906f14f958bd">

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

We can draw these kind of images. 

THere is a module where you can explore the fractal by clicking in (CTRL-click). 

This happens thanks to `KinoJS.Live` as we pass binary between the browser and the Livebook used as a server.

Furthermore, we use Zig embedded code and implemented at the end of the Livebook. It is 2 magnitude faster.

<https://github.com/ndrean/mandelbrot/blob/main/livebook/mandelbrot.livemd>

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
