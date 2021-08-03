import nimib, nimibook

nbInit()
nbUseNimibook()
nbDoc.useLatex

nbText: md"""
# 1D Numerical Integration 
In this tutorial you will learn learn how to use [numericalnim](https://github.com/HugoGranstrom/numericalnim/) to perform 
numerical integration both on discrete data and continuous functions. 

## Integrate Continuous Data
We will start off by integrating some continuous function using a variety of methods and comparing their accuracies and performances
so that you can make an educated choice of method. Let's start off with creating the data to integrate, I have choosen to use
the *humps* function from MATLAB's demos:

$$ f(x) = \frac{1}{(x - 0.3)^2 + 0.01} + \frac{1}{(x - 0.9)^2 + 0.04} - 6 $$ 

It has the primitive function:

$$ F(x) = 10 \arctan(10x - 3) + 5 \arctan(5x - \frac{9}{2}) - 6x $$

Let's code them!
"""

nbCode:
  import math
  import numericalnim
  proc f(x: float, ctx: NumContext[float]): float =
    result = 1 / ((x - 0.3)^2 + 0.01) + 1 / ((x - 0.9)^2 + 0.04) - 6

  proc F(x: float): float =
    result = 10*arctan(10*x-3) + 5*arctan(5*x - 9/2) - 6*x

nbText: md"""
As you can see, we defined `f` not as just `proc f(x: float): float` but added a `ctx: NumContext[float]` as well.
That is because `numericalnim`'s integration methods expect a proc with the signature ``proc f[T](x: float, ctx: NumContext[T]): T``.
That means you can integrate functions *returning* other types than `float` if they have a certain set of supported operations.
We won't be integrating `F` (it is the indefinite integral already) so I skipped adding `ctx` there for simplicity.

Aren't you curious of what `f(x)` looks like? Thought so! Let's plot them using `ggplotnim`,
a more detailed plotting tutorial can be found [here](../data_viz/plotting_data.html).  
"""
nbCode:
  import ggplotnim, sequtils
  let ctxPlot = newNumContext[float]()
  let xPlot = numericalnim.linspace(0, 1, 100)
  let yPlot = xPlot.mapIt(f(it, ctxPlot))
  
  let dfPlot = seqsToDf(xPlot, yPlot)
  ggplot(dfPlot, aes("xPlot", "yPlot")) +
    geom_line() +
    ggsave("images/humps.png")

nbImage("images/humps.png")

nbText: md"""
### Let the integration begin!
Now we have everything we need to start integrating. The specific integral we want to compute is:

$$ \int_0^1 f(x) dx $$

The methods we will use are: `trapz`, `simpson`, `gaussQuad`, `romberg`, `adaptiveSimpson` and `adaptiveGauss`.
Where the last three are adaptive methods and the others are fixed-step methods. We will use a tolerance `tol=1e-6`
for the adaptive methods and `N=100` intervals for the fixed-step methods.
Let's code this now and compare them!
"""

nbCode:
  let a = 0.0
  let b = 1.0
  let tol = 1e-6
  let N = 100
  let exactIntegral = F(b) - F(a)

  let trapzError = abs(trapz(f, a, b, N) - exactIntegral)
  let simpsonError = abs(simpson(f, a, b, N) - exactIntegral)
  let gaussQuadError = abs(gaussQuad(f, a, b, N) - exactIntegral)
  let rombergError = abs(romberg(f, a, b, tol=tol) - exactIntegral)
  let adaptiveSimpsonError = abs(adaptiveSimpson(f, a, b, tol=tol) - exactIntegral)
  let adaptiveGaussError = abs(adaptiveGauss(f, a, b, tol=tol) - exactIntegral)

  echo "Trapz Error:      ", trapzError
  echo "Simpson Error:    ", simpsonError
  echo "GaussQuad Error:  ", gaussQuadError
  echo "Romberg Error:    ", rombergError
  echo "AdaSimpson Error: ", adaptiveSimpsonError
  echo "AdaGauss Error:   ", adaptiveGaussError 

nbText: md"""
It seems like the gauss methods were the most accurate with Romberg and Simpson
coming afterwards and in last place trapz. But at what cost did these scores come at? Which method was the fastest?
Let's find out with a package called `benchy`. `keep` is used to prevent the compiler from optimizing away the code:
"""

nbCode:
  import benchy

  timeIt "Trapz":
    keep trapz(f, a, b, N)

  timeIt "Simpson":
    keep simpson(f, a, b, N)

  timeIt "GaussQuad":
    keep gaussQuad(f, a, b, N)

  timeIt "Romberg":
    keep romberg(f, a, b, tol=tol)

  timeIt "AdaSimpson":
    keep adaptiveSimpson(f, a, b, tol=tol)

  timeIt "AdaGauss":
    keep adaptiveGauss(f, a, b, tol=tol)

nbText: md"""
As we can see, all methods except AdaSimpson were roughly equally fast. So if I were to choose
a winner, it would be `adaptiveGauss` because it was the most accurate while still being among
the fastest methods.

### Cumulative Integration
There is one more type of integration one can do, namely cumulative integration. This is for the case
when you don't just want to calculate the total integral but want an approximation for `F(X)`, so we
need the integral evaluated at multiple points. An example is if we have the acceleration `a(t)` as a function.
If we integrate it we get the velocity, but to be able to integrate the velocity (to get the distance)
we need it as a function, not a single value. That is where cumulative integration comes in!

The methods available to us from `numericalnim` are: `cumtrapz`, `cumsimpson`, `cumGauss` and `cumGaussSpline`.
All methods except `cumGaussSpline` returns the cumulative integral as a `seq[T]`, but this instead returns a
Hermite spline. We will both be calculating the errors and visualizing the different approximations of `F(x)`. 
Let's get coding!
"""

nbCodeInBlock:
  let a = 0.0
  let b = 1.0
  let tol = 1e-6
  let N = 100
  let dx = (b - a) / N.toFloat 

  let x = numericalnim.linspace(a, b, 100)
  var exact = x.mapIt(F(it) - F(a))

  let yTrapz = cumtrapz(f, x, dx=dx)
  let ySimpson = cumsimpson(f, x, dx=dx)
  let yGauss = cumGauss(f, x, tol=tol, initialPoints=x)

  echo "Trapz Error:   ", sum(abs(exact.toTensor - yTrapz.toTensor))
  echo "Simpson Error: ", sum(abs(exact.toTensor - ySimpson.toTensor))
  echo "Gauss Error:   ", sum(abs(exact.toTensor - yGauss.toTensor))

  let df = seqsToDf(x, exact, yTrapz, ySimpson, yGauss)
  # Rewrite df in long format for plotting
  let dfLong = df.gather(["exact", "yTrapz", "ySimpson", "yGauss"], key="Method", value="y")
  ggplot(dfLong, aes("x", "y", color="Method")) +
    geom_line() +
    ggsave("images/continuousHumpsComparaision.png")

nbImage("images/continuousHumpsComparaision.png")

nbText: md"""
As we can see in the graph they are all so close to the exact curve that you can't distingush between
them, but when we look at the total error we see that once again the Gauss method is superior.

> #### Note:
> When we called `cumGauss` we passed in a parameter `initialPoints` as well. The reason for that
is the fact that the Gauss method uses polynomials of degree 21 in its internal calculations while the
final interpolation at the x-values in `x` is performed using a 3rd degree polynomial. This means that Gauss
internally might only need quite few points because of its high degree, but that means we get too few
points for the final 3rd degree interpolation. So to make sure we have enough points in the end we supply
it with enough initial points so that it has enough points to make good predictions even if it doesn't
split any additional intervals.
"""

nbSave()