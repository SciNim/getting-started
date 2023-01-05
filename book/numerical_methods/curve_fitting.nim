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

import std / random
randomize(1337)

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
  let y = yClean + randomNormalTensor(t.shape[0], 0.0, noise)

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

nbCodeInBlock:
  let solution = levmarq(fitFunc, initialGuess, t, y)
  echo solution

nbText: hlMd"""
As we can see, the found parameters are very close to the actual ones. But maybe we can do better,
`levmarq` accepts an `options` parameter which is the same as the one described in [Optimization](./optimization.html)
with the addition of the `lambda0` parameter. We can reduce the `tol` and see if we get an even better fit:
"""

nbCode:
  let options = levmarqOptions(tol=1e-15)
  let solution = levmarq(fitFunc, initialGuess, t, y, options=options)
  echo solution

nbText: hlMd"""
As we can see, there isn't really any difference. So we can conclude that the
found solution has in fact converged. 

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

## Errors & Uncertainties
We might also want to quantify exactly how good of a fit the computed weights give.
One measure commonly used is [$\chi^2$](https://en.m.wikipedia.org/wiki/Pearson%27s_chi-squared_test):
$$\chi^2 = \sum_i \frac{(y_i - \hat{y}(x_i))^2}{\sigma_i^2}$$ 
where $y_i$ and $x_i$ are the measurements, $\hat{y}$ is the fitted curve and $\sigma_i$
is the standard deviation (uncertainty/error) of each of the measurements. We will use the
noise size we used when generating the samples here, but in general you will have to
figure out yourself what errors are in your situation. It may for example be the resolution
of your measurements or you may have to approximate it using the data itself. 

We now create the error vector and sample the fitted curve:
"""

nbCode:
  let yError = ones_like(y) * noise
  let yCurve = t.map_inline:
    fitFunc(solution, x)

nbText: """
Now we can calculate the $\chi^2$:
"""

nbCode:
  var chi2 = 0.0
  for i in 0 ..< y.len:
    chi2 += ((y[i] - yCurve[i]) / yError[i]) ^ 2
  echo "χ² = ", chi2

nbText: hlMd"""
Great! Now we have a measure of how good the fit is, but what if we add more points?
Then we will get a better fit, but we will also get more points to sum over.
And what if we choose another curve to fit with more parameters?
Then we may be able to get a better fit but we risk overfitting.
[Reduced $\chi^2$](https://en.m.wikipedia.org/wiki/Reduced_chi-squared_statistic)
is a measure which adjusts $\chi^2$ to take these factors into account.
The formula is:
$$\chi^2_{\nu} = \frac{\chi^2}{n_{\text{obs}} - m_{\text{params}}}$$
where $n_{\text{obs}}$ is the number of observations and $m_{\text{params}}$
is the number of parameters in the curve. The difference between them is denoted
the degrees of freedom (dof).
This is simplified, the mean $\chi^2$
score adjusted to penalize too complex curves.

Let's calculate it!
"""

nbCode:
  let reducedChi2 = chi2 / (y.len - solution.len).float
  echo "Reduced χ² = ", reducedChi2

nbText: hlMd"""
As a rule of thumb, values around 1 are desirable. If it is much larger
than 1, it indicates a bad fit. And if it is much smaller than 1 it means
that the fit is much better than the uncertainties suggested. This could
either mean that it has overfitted or that the errors were overestimated.

### Parameter uncertainties
To find the uncertainties of the fitted parameters, we have to calculate
the covariance matrix:
$$\Sigma = \sigma^2 H^{-1}$$
where $\sigma^2$ is the standard deviation of the residuals and $H$ is
the Hessian of the objective function (we used $\chi^2$). 
We must first construct the objective function as a function of the
parameters that outputs a scalar score. We will construct it the same
way we have done above:
"""

nbCode:
  proc objectiveFunc(params: Tensor[float]): float =
    let yCurve = t.map_inline:
      fitFunc(params, x)
    result = sum(((y - yCurve) /. yError) ^. 2)

nbText: hlMd"""
Now we approximate $\sigma^2$ by the reduced $\chi^2$ at the fitted parameters:
"""

nbCode:
  let sigma2 = objectiveFunc(solution) / (y.len - solution.len).float
  echo "σ² = ", sigma2

nbText: """
The Hessian at the solution can be calculated numerically using `tensorHessian`:
"""

nbCode:
  let H = tensorHessian(objectiveFunc, solution)
  echo "H = ", H

nbText: "Now we calculate the covariance matrix as described above:"

nbCode:
  proc eye(n: int): Tensor[float] =
    result = zeros[float](n, n)
    for i in 0 ..< n:
      result[i,i] = 1

  proc inv(t: Tensor[float]): Tensor[float] =
    result = solve(t, eye(t.shape[0]))

  let cov = sigma2 * H.inv()
  echo "Σ = ", cov

nbText: """
The diagonal elements of the covariance matrix is the uncertainty (variance) in our parameters,
so we take the square root of them to get the standard deviation:
"""

nbCode:
  proc getDiag(t: Tensor[float]): Tensor[float] =
    let n = t.shape[0]
    result = newTensor[float](n)
    for i in 0 ..< n:
      result[i] = t[i,i]

  let paramUncertainty = sqrt(cov.getDiag())
  echo "Uncertainties: ", paramUncertainty

nbText: """
All in all, these are the values and uncertainties we got for each of the parameters:
"""

nbCode:
  echo "α = ", solution[0], " ± ", paramUncertainty[0]
  echo "β = ", solution[1], " ± ", paramUncertainty[1]
  echo "γ = ", solution[2], " ± ", paramUncertainty[2]
  echo "δ = ", solution[3], " ± ", paramUncertainty[3]

nbText: hlMd"""
## Further reading
- [numericalnim's documentation on optimization](https://scinim.github.io/numericalnim/numericalnim/optimize.html)
"""

nbSave
