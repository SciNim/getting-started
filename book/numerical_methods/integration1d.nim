import nimib, nimibook

nbInit()
nbUseNimibook()
nbDoc.useLatex

nbText: md"""
# 1D Numerical Integration 
In this tutorial you will learn learn how to use [numericalnim](https://github.com/HugoGranstrom/numericalnim/) to perform 
numerical integration both on discrete data and continuous functions. 

## Integrate Continuous Functions
We will start off by integrating some continuous function using a variety of methods and comparing their accuracies and performances
so that you can make an educated choice of method. Let's start off with creating the data to integrate, I have choosen to use
the *humps* function from MATLAB's demos:

$$ f(x) = \frac{1}{(x - 0.3)^2 + 0.01} + \frac{1}{(x - 0.9)^2 + 0.04} - 6 $$ 

It has the primitive function:

$$ F(x) = 10 \arctan(10x - 3) + 5 \arctan(5x - \frac{9}{2}) - 6x $$

Let's code them!
"""

nbCode:
  import math, sequtils
  import numericalnim, ggplotnim, benchy
  proc f(x: float, ctx: NumContext[float]): float =
    result = 1 / ((x - 0.3)^2 + 0.01) + 1 / ((x - 0.9)^2 + 0.04) - 6

  proc F(x: float): float =
    result = 10*arctan(10*x-3) + 5*arctan(5*x - 9/2) - 6*x

block continuousPart: # Want to be able to use cross-codeblock variables, but also separate each part of the tutorial.

  nbText: md"""
As you can see, we defined `f` not as just `proc f(x: float): float` but added a `ctx: NumContext[float]` as well.
That is because `numericalnim`'s integration methods expect a proc with the signature ``proc f[T](x: float, ctx: NumContext[T]): T``.
That means you can integrate functions *returning* other types than `float` if they have a certain set of supported operations.
We won't be integrating `F` (it is the indefinite integral already) so I skipped adding `ctx` there for simplicity.

Aren't you curious of what `f(x)` looks like? Thought so! Let's plot them using `ggplotnim`,
a more detailed plotting tutorial can be found [here](../data_viz/plotting_data.html).  
  """

  nbCodeInBlock:
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
      geom_point() +
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
split any additional intervals. By default it uses 100 equally spaced points though so unless you know you
need far more or less points you should be good. 
This is especially important when using `cumGaussSpline` as we need enough
points to construct an accurate spline. 

The last method is `cumGaussSpline` which is identical to `cumGauss` except it constructs a Hermite spline
from the returned values which can be evaluated when needed. 
  """

  nbCodeInBlock:
    let a = 0.0
    let b = 1.0
    let tol = 1e-6

    let spline = cumGaussSpline(f, a, b, tol=tol)

    echo "One point: ", spline.eval(0.0) # evaluate it in a single point
    echo "Three points: ", spline.eval(@[0.0, 0.5, 1.0]) # or multiple at once

    # Thanks to converter you can integrate a spline by passing it as the function:
    echo "Integrate it again: ", adaptiveGauss(spline, a, b)

  nbText: md"""
  I think that about wraps it up regarding integrating continuous functions! Let's take a look at
  integrating discrete data now!

## Integrate Discrete Data

Discrete data is a different beast than continuous functions as we have limited data. Therefore the choice
of integration method is even more important as we can't exchange performance to get more accurate result
like we can with continuous function (we can increase the number of intervals for example). So we want to make the
most out of the data we have, and any knowledge we have about the nature of the data is helpful. 
For example if we know the data isn't smooth (discontinuities), then trapz could be a better choice
than let's say simpson because simpson assumes the data is smooth. 

Let's sample `f(x)` from above at let's say 9 points and plot how much information we lose by
plotting the sampled points, a Hermite Spline interpolation of them and the original function:
"""

block discretePart:
  nbCode:
    var xSample = numericalnim.linspace(0.0, 1.0, 9)
    var ySample = xSample.mapIt(f(it, nil)) # nil can be passed in instead of ctx if we don't use it

    let xDense = numericalnim.linspace(0, 1, 100) # "continuous" x
    let yDense = xDense.mapIt(f(it, nil))

    var sampledSpline = newHermiteSpline(xSample, ySample)
    var ySpline = sampledSpline.eval(xDense)

    var dfSample = seqsToDf(xSample, ySample, xDense, yDense, ySpline)
    ggplot(dfSample) +
      geom_point(aes("xSample", "ySample", color="Sampled")) +
      geom_line(aes("xDense", "ySpline", color="Sampled")) +
      geom_line(aes("xDense", "yDense", color="Dense")) +
      scale_x_continuous() + scale_y_continuous() +
      ggsave("images/sampledHumps.png")

  nbImage("images/sampledHumps.png")

  nbText: md"""
As you can see, the resolution was too small to fully account for the big peak and undershoots it by quite a margin.
Without having known the "real" function in this case we wouldn't have known this of course, and that is most often the
case when we have discrete data. Therefore, the resoltion of the data is crucial for the accuracy. But let's say this 
is all the data we have at our disposal and let's see how the different methods perform. 

The integration methods at our disposal are: 
- `trapz`: Works for any data.
-  `simpson`: Works for any data with 3 or more data points.
- `romberg`: Works **only** for equally spaced points. The number of points must also be 
of the form `2^n + 1` (eg. 3, 5, 9, 17, 33 etc).

Luckily for us our data satisfies all of them ;) So let's get coding:
  """

  nbCode:
    let exact = F(1) - F(0)

    var trapzIntegral = trapz(ySample, xSample)
    var simpsonIntegral = simpson(ySample, xSample)
    var rombergIntegral = romberg(ySample, xSample)

    echo "Exact:   ", exact
    echo "Trapz:   ", trapzIntegral
    echo "Simpson: ", simpsonIntegral
    echo "Romberg: ", rombergIntegral
    echo "Trapz Error:   ", abs(trapzIntegral - exact)
    echo "Simpson Error: ", abs(simpsonIntegral - exact)
    echo "Romberg Error: ", abs(rombergIntegral - exact)

  nbText: md"""
As expected all the methods underestimated the integral, but it might be unexpected that
trapz performed the best out of them. Let's add a few more points, why not 33, and let's see if 
that changes things!
  """

  nbCode:
    xSample = numericalnim.linspace(0.0, 1.0, 33)
    ySample = xSample.mapIt(f(it, nil))

    sampledSpline = newHermiteSpline(xSample, ySample)
    ySpline = sampledSpline.eval(xDense)

    dfSample = seqsToDf(xSample, ySample, xDense, yDense, ySpline)
    ggplot(dfSample) +
      geom_point(aes("xSample", "ySample", color="Sampled")) +
      geom_line(aes("xDense", "ySpline", color="Sampled")) +
      geom_line(aes("xDense", "yDense", color="Dense")) +
      scale_x_continuous() + scale_y_continuous() +
      ggsave("images/sampledHumps33.png")

    trapzIntegral = trapz(ySample, xSample)
    simpsonIntegral = simpson(ySample, xSample)
    rombergIntegral = romberg(ySample, xSample)

    echo "Exact:   ", exact
    echo "Trapz:   ", trapzIntegral
    echo "Simpson: ", simpsonIntegral
    echo "Romberg: ", rombergIntegral
    echo "Trapz Error:   ", abs(trapzIntegral - exact)
    echo "Simpson Error: ", abs(simpsonIntegral - exact)
    echo "Romberg Error: ", abs(rombergIntegral - exact)

  nbImage("images/sampledHumps33.png")

  nbText: md"""
As expected all methods became more accurate when we increased the amount of points.
And from the graph we can see that the points capture the shape of the curve much better now.
We can also note that simpson has overtaken trapz and romberg is neck-in-neck with trapz now.
Experiment for yourself with different number of points, but asymtotically romberg will eventually
beat simpson when enough points are used. 

The take-away from this very limited testing is that depending on the characteristics and quality
of the data, different methods might give the most accurate answer. Which one is hard to tell in general
but trapz *might* be more robust for very sparse data as it doesn't "guess" as much as the others. But once again,
it entirely depends on the data, so make sure to understand your data!  
  """
nbSave()