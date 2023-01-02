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
- [Linear](https://en.wikipedia.org/wiki/Linear_interpolation): `newLinear1D`
- [Cubic spline](https://en.wikipedia.org/wiki/Spline_interpolation): `newCubicSpline` (only supports floats)
- [Hermite spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline): `newHermiteSpline`

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
- [Nearest neighbour](https://en.wikipedia.org/wiki/Nearest-neighbor_interpolation): `newNearestNeighbour2D`
- [Bilinear](https://en.wikipedia.org/wiki/Bilinear_interpolation): `newBilinearSpline`
- [Bicubic](https://en.wikipedia.org/wiki/Bicubic_interpolation): `newBicubicSpline`

and 2 methods for scattered data:

- [Barycentric](https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/barycentric-coordinates.html): `newBarycentric2D`
- [Radial basis function](https://en.wikipedia.org/wiki/Radial_basis_function_interpolation): `newRbf`
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
We can now plot the function to see how much it resembles the original function (the dots are the sampled points):  
"""

  block:
    let coords = meshgrid(arraymancer.linspace(-1.0, 0.999, 100), arraymancer.linspace(-1.0, 0.999, 100))
    let sampleCoords = meshgrid(arraymancer.linspace(-1.0, 1.0, 5), arraymancer.linspace(-1.0, 1.0, 5))
    var z = zeros[float](coords.shape[0])
    var exact = zeros[float](coords.shape[0])
    for i in 0 ..< coords.shape[0]:
      z[i] = interp.eval(coords[i, 0], coords[i, 1])
      exact[i] = f(coords[i, 0], coords[i, 1])
    let df = toDf({"x": coords[_,0].squeeze, "y": coords[_,1].squeeze, "z": z, "error": abs(exact - z),
      "xSample": sampleCoords[_,0].squeeze, "ySample": sampleCoords[_,1].squeeze})
    ggplot(df, aes("x", "y", fill = "z")) +
      geom_raster() +
      geom_point(aes("xSample", "ySample"), color = "#F92672") +
      xlim(-1, 1) +
      ylim(-1, 1) +
      ggtitle("Interpolator result") +
      ggsave("images/2d_interp_eval.png")

    ggplot(df, aes("x", "y", fill="error")) +
      geom_raster() +
      geom_point(aes("xSample", "ySample"), color = "#F92672") +
      xlim(-1, 1) +
      ylim(-1, 1) +
      ggtitle("Error") +
      ggsave("images/2d_interp_error.png")
    
  nbImage("images/2d_interp_eval.png")
  nbImage("images/2d_interp_error.png")

  nbText: hlMd"""
It looks pretty similar to the original function so I'd say it did a good job.
We have also plotted the error in the second image. We can see that the
interpolant is the most accurate close to the sampled points and the least 
accurate between them. 
"""

block Part3:
  nbText: hlMd"""
## ND interpolation
With the addition of Radial basis function (RBF) interpolation, `numericalnim` now offers an
interpolation method that works for **scattered** data of **arbitrary dimensions**. 
The conceptual explanation for how RBF interpolation works is that a Gaussian is placed at
each of the data points. These are then each scaled such that the sum of all the Gaussians
pass through all the data points exactly.

Further, the implemented method employs localization using Partition of Unity. This is a
method that exploits the fact that a Gaussian decays very quickly. Hence we shouldn't 
have to take into account points far away from the point we are interested in. So internally
a grid structure is created such that points are only affected by their neighbors. This both
speeds up the code but does also make it more numerically stable.

The format of the inputs that is expected is the positions as a `Tensor` of of shape `(nPoints, nDims)`
and the function values (can be multi-valued) of shape `(nPoints, nValues)`. In the general case
the points aren't gridded but if you want to create points on a grid you can do it with the
`meshgrid` function. It takes in a `vararg` of `Tensor[float]`, one `Tensor` for each dimension containing the
grid values in that dimension. An example is: 
"""

  nbCode:
    let x = meshgrid(arraymancer.linspace(-1.0, 1.0, 5), arraymancer.linspace(-1.0, 1.0, 5), arraymancer.linspace(-1.0, 1.0, 5))
    echo x[0..10, _]
  
  nbText: hlMd"""
which will create a 3D grid with 5 points between -1 and 1 in each of the dimensions.

Now let's define a function we going to interpolate:
$$f(x, y, z) = \sin(x) \sin(y) \sin(z)$$
Here's the code for implementing it:
"""

  nbCode:
    proc f(x: Tensor[float]): Tensor[float] =
      product(sin(x), axis=1)
      
    let y = f(x)

  nbText: hlMd"""
Now we can construct the interpolator as such:  
"""

  nbCode:
    let interp = newRbf(x, y)

  nbText: "Evaluation is done by calling `eval` with the evaluation point(s):"

  nbCode:
    let xEval = [[0.5, 0.5, 0.5], [0.6, 0.5, 0.3], [0.75, -0.23, 0.46]].toTensor
    echo interp.eval(xEval).squeeze
    echo f(xEval).squeeze

  nbText: hlMd"""
As we can see by comparing the exact solution with the interpolant, they are pretty close to each other.

## Conclusion
As we have seen, you can do all sorts of interpolations in Nim with just a few lines of code. 
Have a nice day!

## Further reading
[Curve fitting](https://scinim.github.io/getting-started/numerical_methods/curve_fitting.html) is a method you can use
if you know the parametric form of the function of the data you want to interpolate.
"""


nbSave