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
  import numericalnim, ggplotnim, std/[math, sequtils]

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

nbText: hlMd"""
## 2D interpolation
"""

nbText: hlMd"""
## ND interpolation

"""

nbSave