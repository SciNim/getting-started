import nimib except Value
import nimibook
import std / [strformat]


nbInit(theme = useNimibook)
nb.useLatex

nbText: hlMd"""
# Interpolate discrete data in Nim
Very seldom when dealing with real data do you have an exact function you can evaluate at any point you would like.
Often you have data in a finite number of discrete points instead. Two common ways to solve this problem is to either
interpolate the data or if you know the form it should take you can do curve fitting. In this tutorial we will cover the
interpolation approach in 1D, 2D and 3D for some cases.

We will be using [numericalnim](https://github.com/SciNim/numericalnim) for this and the imports we will need are:
"""

nbCode:
  import numericalnim, arraymancer, ggplotnim, std/[math, sequtils]

block Part1:
  nbText: hlMd"""
## 1D Interpolation
This is the simplest case of interpolation and `numericalnim` can handle both evenly spaced and variable spacing in 1D.
We will use the function $f(x) = sin(3x) (x-2)^2$ for our benchmarks:
"""

  block:
    let t = linspace(0.0, 4.2, 100)
    let y = t.mapIt(sin(3*it) * (it - 2)^2)
    let df = toDf(t, y)
    ggplot(df, aes("t", "y")) +
      geom_line() +
      ggtitle("f(x)") +
      ggsave("images/1dinterpolation_f.png")

  nbImage("images/1dinterpolation_f.png")

  nbText: hlMd"""
Let's get interpolating! We first define the function and sample from it:
"""

  nbCode:
    proc f(x: float): float = sin(3*x) * (x - 2)^2

    let x = linspace(0.0, 4.2, 10)
    let y = x.map(f)

  nbText: hlMd"""
Now we are ready to create the interpolator! For 1D there are these options available:
- Linear: `newLinear1D`
- Cubic spline: `newCubicSpline` (only supports floats)
- Hermite spline: `newHermiteSpline`

They all have the same API accepting `seq`s of x- and y-values.
The Hermite spline can optionally supply the derivatives at each point as well.
We will be using the Hermite spline without the derivatives, they will be approximated
using finite differences for us.
"""

  nbCode:
    let interp = newHermiteSpline(x, y)

  nbText: hlMd"""
Now that we have constructed the interpolator, we can evaluate it using `eval`.
It accepts either a single input or a `seq` of inputs:
"""

  nbCode:
    echo interp.eval(1.0)
    echo interp.eval(@[1.0, 2.0])

  nbText: hlMd"""
We can now evaluate it on a denser set of points and compare it to the original function:  
"""

  block:
    let t = linspace(0.0, 4.2, 100)
    let yOriginal = t.map(f)
    let yInterp = interp.eval(t)
    var df = toDf(x, y, t, yOriginal, yInterp)
    df = df.gather(@["yOriginal", "yInterp"], key = "Class", value = "Value")
    ggplot(df, aes("t", "Value", color="Class")) +
      geom_line() +
      geom_point(aes("x", "y")) +
      ggsave("images/compare_interp.png")

  nbImage("images/compare_interp.png")

  nbText: hlMd"""
As we can see, the interpolant does a decent job of approximating the function.
It is worse where the function is changing a lot and closer to the original
in the middle where there is less happening.  
"""

block Part2:
  nbText: hlMd"""
## 2D interpolation
For 2D interpolation, `numericalnim` offers 3 methods for gridded data:
- `newNearestNeighbour2D`
- `newBilinearSpline`
- `newBicubicSpline`

and 2 methods for scattered data:

- `newBarycentric2D`
- `newRbf`
The RBF method isn't unique to 2D and works for any dimension, see the next section for more on that.
For this tutorial, we will focus on the Bicubic spline but NearestNeighbour and Bilinear spline have the same API.
Let's first choose a suitable function to interpolate:
$$f(x, y) = e^{-(x^2 + y^2)}$$
This will be a Gaussian centered around `(0, 0)`, here's a heatmap showing the function:
"""

  block:
    let coords = meshgrid(arraymancer.linspace(-1.0, 1.0, 100), arraymancer.linspace(-1.0, 1.0, 100))
    let z = exp(-1.0 * sum(coords *. coords, axis=1)).squeeze()
    let df = toDf({"x": coords[_,0].squeeze, "y": coords[_,1].squeeze, "z": z})
    ggplot(df, aes("x", "y", fill = "z")) +
      geom_raster() +
      xlim(-1, 1) +
      ylim(-1, 1) +
      ggsave("images/2d_interp_func.png")
  
  nbImage("images/2d_interp_func.png")

  nbText: hlMd"""
Now we are ready to sample our function. The inputs expected are the limits in $x$ and $y$ along
with the function values in grid as a Tensor. So if we have a 3x3 grid of data points, the Tensor
should have shape 3x3 as well. Because the data is known to be on a grid, you don't have to give
all the points on it, it's enough to only provide the limits as two tuples.
"""

  nbCode:
    proc f(x, y: float): float =
      exp(-(x*x + y*y))
    
    let xlim = (-1.0, 1.0)
    let ylim = (-1.0, 1.0)

    let xs = linspace(xlim[0], xlim[1], 5)
    let ys = linspace(ylim[0], ylim[1], 5)
    var z = zeros[float](xs.len, ys.len)
    for i, x in xs:
      for j, y in ys:
        z[i, j] = f(x, y)
    
  nbText: "Now we have sampled our function, let's construct the interpolator:"

  nbCode:
    let interp = newBicubicSpline(z, xlim, ylim)

  nbText: "The interpolator can now be evaluated using `eval`:"

  nbCode:
    echo interp.eval(0.0, 0.0)

  nbText: hlMd"""
We can now plot the function to see how much it resembles the original function:  
"""

  block:
    let coords = meshgrid(arraymancer.linspace(-1.0, 0.999, 100), arraymancer.linspace(-1.0, 0.999, 100))
    var z = zeros[float](coords.shape[0])
    for i in 0 ..< coords.shape[0]:
      z[i] = interp.eval(coords[i, 0], coords[i, 1])
    let df = toDf({"x": coords[_,0].squeeze, "y": coords[_,1].squeeze, "z": z})
    ggplot(df, aes("x", "y", fill = "z")) +
      geom_raster() +
      xlim(-1, 1) +
      ylim(-1, 1) +
      ggsave("images/2d_interp_eval.png")
    
  nbImage("images/2d_interp_eval.png")

  nbText: hlMd"""
It looks pretty similar to the original function so I'd say it did a good job.
"""

block Part3:
  nbText: hlMd"""
## ND interpolation

"""

nbSave