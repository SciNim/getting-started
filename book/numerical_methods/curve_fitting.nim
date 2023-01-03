import nimib, nimibook
import mpfit, ggplotnim

nbInit(theme = useNimibook)
nb.useLatex

# Vindaar's part:
#[ nbText: """
# Curve fitting using [mpfit](https://github.com/Vindaar/nim-mpfit)

This section will cover a curve fitting example. It assumes you are familiar with the
data type and plotting introductions from the "Introduction" section. Here we will
combine this knowledge to perform a simple curve fit at the end.

With our acquired knowledge, we will now:
- read some data from a CSV file into a data frame
- perform a curve fit on the data using some functio
- compute the fit result as a line
- draw a plot containing: input data + error bars, fit, fit results

## read csv

## fit function

## compute fit result

## plot data + fit results

yes.

"""

nbText: """
""" ]#

nbText: hlMd"""
## Curve fitting using `numericalnim`
[Curve fitting](https://en.wikipedia.org/wiki/Curve_fitting) is the task of finding the "best" parameters for a given function,
such that it minimizes the error on the given data. The simplest example being,
finding the slope and intersection of a line $y = ax + b$ using such that it minimizes the squared errors
between the data points and the line.
[numericalnim](https://github.com/SciNim/numericalnim) implements the [Levenberg-Marquardt algorithm](https://en.wikipedia.org/wiki/Levenberg%E2%80%93Marquardt_algorithm)(`levmarq`)
for solving non-linear least squares problems. One such problem is curve fitting, which aims to find the parameters that (locally) minimizes
the error between the data and the fitted curve.

The required imports are:
"""

nbCode:
  import numericalnim, ggplotnim, arraymancer, std / [math, sequtils]

nbText: hlMd"""
In some cases you know the actual form of the function you want to fit,
but in other cases you may have to guess and try multiple different ones.
In this tutorial we will assume we know the form but it works the same regardless.
The test curve we will sample points from is
$$f(t) = \alpha + \sin(\beta t + \gamma) e^{-\delta t}$$
with $\alpha = 0.5, \beta = 6, \gamma = 0.1, \delta = 1$. This will be a decaying sine wave with an offset.
We will add a bit of noise to it as well:
"""

nbCode:
  proc f(alpha, beta, gamma, delta, t: float): float =
    alpha + sin(beta * t + gamma) * exp(-delta*t)

  let
    alpha = 0.5
    beta = 6.0
    gamma = 0.1
    delta = 1.0
  let t = arraymancer.linspace(0.0, 3.0, 20)
  let yClean = t.map_inline:
    f(alpha, beta, gamma, delta, x)
  let noise = 0.025
  let y = yClean + randomTensor(t.shape[0], 2*noise) -. noise

let tDense = arraymancer.linspace(0.0, 3.0, 200)
let yDense = tDense.map_inline:
  f(alpha, beta, gamma, delta, x)

block:
  let df = toDf(t, y, tDense, yDense)
  df.ggplot(aes("t", "y")) +
    geom_point() +
    geom_line(aes("tDense", "yDense")) +
    ggsave("images/levmarq_rawdata.png")

nbImage("images/levmarq_rawdata.png")

nbText: hlMd"""
Here we have the original function along with the sampled points with noise.
Now we have to create a proc that `levmarq` expects. Specifically it
wants all the parameters in a `Tensor` instead of by themselves: 
"""

nbCode:
  proc fitFunc(params: Tensor[float], t: float): float =
    let alpha = params[0]
    let beta = params[1]
    let gamma = params[2]
    let delta = params[3]
    result = f(alpha, beta, gamma, delta, t)

nbText: hlMd"""
As we can see, all the parameters that we want to fit, are passed in as
a single 1D Tensor that we unpack for clarity here. The only other thing
that is needed is an initial guess of the parameters. We will set them to all 1 here: 
"""

nbCode:
  let initialGuess = ones[float](4)

nbText: "Now we are ready to do the actual fitting:"

nbCode:
  let solution = levmarq(fitFunc, initialGuess, t, y)
  echo solution

nbText: hlMd"""
As we can see, the found parameters are very close to the actual ones.
Here's a plot comparing the fitted and original function:
"""

block:
  let ySol = tDense.map_inline:
    fitFunc(solution, x)

  var df = toDf({"t": tDense, "original": yDense, "fitted": ySol, "tPoint": t, "yPoint": y})
  df = df.gather(@["original", "fitted"], key="Class", value = "y")
  df.ggplot(aes("t", "y", color="Class")) +
    geom_line() +
    geom_point(aes("tPoint", "yPoint")) +
    ggsave("images/levmarq_comparision.png")

nbImage("images/levmarq_comparision.png")

nbText: hlMd"""
As we can see, the fitted curve is quite close to the original one.
"""

nbSave
