# Mandelbrot Set

## Introduction

Source:

- [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set)
- [Plotting algorithm](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set)

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
