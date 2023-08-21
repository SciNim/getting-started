import nimib except Value
import nimibook

nbInit(theme = useNimibook)
nb.useLatex

nbText: hlMd"""
# Bayesian Inference with Linear Model

At the time of this writing, Nim does not have any libraries for
conducting Bayesian inference. However, it is quite easy for us to
write all of the necessary code ourselves. This is a good exercise for learning
about Bayesian inference and the syntax and speed of Nim make it an excellent
choice for the this. In this tutorial we will walk through
the different parts needed to perform Bayesian inference with a linear model.
We will assume that you have some basic understanding of Bayesian
inference already. There are many excellent introductions available in books
and online.

Bayes theorem states:

$$ P(\theta|\text{Data}) = \frac{P(\text{Data}|\theta)P(\theta)}{P(\text{Data})}$$

Each of these terms are referred to as:

$$ \text{Posterior} = \frac{\text{Likelihood} \cdot \text{Prior}}{\text{Marginal Likelihood}}$$

A marginal probability $P(\text{Data}) $ can be discrete probability distribution 
where $P(\text{Data}) = \sum_{\theta}P(\text{Data}|\theta)P(\theta)$ so the posterior
probability distribution is:

$$ P(\theta|\text{Data}) = \frac{P(\text{Data}|\theta)P(\theta)}{\sum_{\theta}P(\text{Data}|\theta)P(\theta)}$$

Or a marginal probability can be a continuous probability distribution
where $P(\text{Data}) = \int d\theta P(\text{Data}|\theta)P(\theta)$ so the posterior
probability distribution is:

$$ P(\theta|\text{Data}) = \frac{P(\text{Data}|\theta)P(\theta)}{\int d\theta P(\text{Data}|\theta)P(\theta)}$$

In this tutorial we will condsider a simple linear model
$ y_{i} = \beta_{0} + \beta_{1} x_{i} + \epsilon_{i} $ where $\epsilon \sim N(0, \tau)$.
Under this model, the parameters $\beta_0$ (y intercept) and $\beta_1$ (slope),
describe the relationship between a
predictor variable $x$ and a response variable $y$, with some unaccounted for
residual random error ($\epsilon$) which is normally distributed with a mean of $0$ and
standard deviation $\tau$.

We will estimate the values of the slope ($\beta_{0}$), the y-intercept
($\beta_{1}$), and the standard deviation of the residual random error ($\tau$)
from observed $x$ and $y$ data.

Expressing this with Bayes rule gives us:

$$ \displaystyle P(\beta_{0}, \beta_{1}, \tau | Data) =
  \frac{P(Data|\beta_{0}, \beta_{1}, \tau) P(\beta_{0}, \beta_{1}, \tau)}
  {\iiint d\beta_{0} d\beta_{1} d\tau P(Data|\beta_{0}, \beta_{1}, \tau) P(\beta_{0}, \beta_{1}, \tau)} $$


# Generate Data
We need some data to work with. Let's simulate data
under the model wth $\beta_{0}=0$, $\beta_{1}=1$, and $\tau=1$:

$ y = 0 + 1x + \epsilon$ where $\epsilon \sim N(0, 1) $

"""

nbCode:
  import std/sequtils, std/random, std/stats
  var
    n = 100
    b0 = 0.0
    b1 = 1.0
    sd = 1.0
    x = newSeq[float](n)
    y = newSeq[float](n)
  for i in 0 ..< n:
    x[i] = rand(0.0..100.0)
    y[i] = b0 + (b1 * x[i]) + gauss(0.0, sd)

nbText: hlMd"""
We can use `ggplotnim` to see what these data look like.
"""

nbCode:
  import datamancer, ggplotnim
  var sim = toDf(x, y)
  ggplot(sim, aes("x", "y")) +
    geom_point() +
    ggsave("images/simulated-data.png")
nbImage("images/simulated-data.png")

nbText: hlMd"""
# Priors
We need to choose prior probability distributions for each of the model parameters
that we are estimating.  Let's use a normal distribution for the priors on
$\beta_{0}$ and $\beta_{1}$. The $\tau$ parameter must be a positive value
greater than 0 so let's use the gamma distribution as the prior on $\tau$.

$$ \beta_{0} \sim Normal(\mu_{0}, \sigma^{2})$$
$$ \beta_{1} \sim Normal(\mu_{1}, \sigma^{2})$$
$$ \tau \sim Gamma(\kappa_{0}, \theta_{0})$$

To calculate the prior probabilities of proposed model parameter values, we will need
the proability density functions for these distributions.

#### Normal PDF
$$ p(x) = \frac{1}{\sigma\sqrt{2\pi}} e^{-\frac{1}{2}(\frac{x-\mu}{\sigma})^{2}} $$

#### Gamma PDF
$$ p(x) = \frac{1}{\Gamma(k)\theta^{k}} x^{k-1} e^{-\frac{x}{\theta}} $$
"""

nbCode:
  import std/math

  proc normalPdf(x, m, s: float): float =
    result = E.pow((-0.5 * ((x - m) / s)^2)) / (s * sqrt(2.0 * PI))

  proc gammaPdf(x, k, t: float): float =
    result = x.pow(k - 1.0) * E.pow(-(x / t)) / (gamma(k) * t.pow(k))

nbText: hlMd"""
We now need to decide how to parameterize these prior probability densities.
Since this is for the purpose of demonstration, let's use very informed
priors so that we can quickly get a good sample from the posterior.

$$ \beta_{0} \sim Normal(0, 1)$$
$$ \beta_{1} \sim Normal(1, 1)$$
$$ \tau \sim Gamma(1, 1)$$

In a real analysis, the priors should encompass all values that we consider possible and
it may also be a good idea to examine how sensitive the analysis is to the choice
of priors.
"""

nbCode:
  type
    Normal = object
      mu: float
      sigma: float

    Gamma = object
      k: float
      sigma: float

    Priors = object
      b0: Normal
      b1: Normal
      sd: Gamma

  var priors = Priors(
    b0: Normal(mu:0.0, sigma:10.0),
    b1: Normal(mu:1.0, sigma:10.0),
    sd: Gamma(k:1.0, sigma:10.0))

nbText: hlMd"""
Now that we have prior probability density functions for each model parameter
that we are estimating, we need to be able to compute the joint prior probability
for all of the parameters of the model.
We will actually be using the $ln$ of the probabilities to
reduce rounding error since these values can be quite small.
"""

nbCode:
  proc logPrior(priors: Priors, b0, b1, sd: float ): float =
    let
      b0Prior = ln(normalPdf(b0, priors.b0.mu, priors.b0.sigma))
      b1Prior = ln(normalPdf(b1, priors.b1.mu, priors.b1.sigma))
      sdPrior = ln(gammaPdf(sd, priors.sd.k, priors.sd.sigma))
    result = b0Prior + b1Prior + sdPrior

nbText: hlMd"""
# Likelihood
We need to be able to calculate the likelihood of the observed $y_{i}$ values
given the observed $x_{i}$ values and the model parameter values, $\beta_{0}$,
$\beta_{1}$, and $\tau$.

We can write the model in a slightly different way:

$$\mu = \beta_{0} +\beta_{1} x$$
$$ y \sim N(\mu, \tau) $$

Then to compute the likelihood for a given set of $\beta_{0}$, $\beta_{1}$, $\tau$
parameters and data values $x_{i}$ and $y_{i}$ we use the normal probability
density function which we wrote before to compute our prior probabilities.
We will work with the $ln$ of the likelihood as we did with the priors.
"""

nbCode:
  proc logLikelihood(x, y: seq[float], b0, b1, sd: float): float =
    var likelihoods = newSeq[float](y.len)
    for i in 0 ..< y.len:
      let pred = b0 + (b1 * x[i])
      likelihoods[i] = ln(normalPdf(y[i], pred, sd))
    result = sum(likelihoods)

#TODO: Finish
nbText: hlMd"""
# Posterior
We cannot analytically solve the posterior probability distribution of our
linear model as the integration of the marginal likelihood is intractable.

But we can approximate it with markov chain monte carlo (MCMC) thanks to this
property of Bayes rule:

$$ \displaystyle P(\beta_{0}, \beta_{1}, \tau | Data) \propto
  P(Data|\beta_{0}, \beta_{1}, \tau) P(\beta_{0}, \beta_{1}, \tau) $$

The marginal likelihood is a normalizing constant. Without it, we no longer
have a probability density function. But the relative probability of a given set
of parameter values to another set is the same. We only care about which parameter
values are most probable so this is enough for us. We can determine which values
have higher probability by randomly walking through parameter space while accepting
or rejecting new values based on how probable they are.

"""

nbCode:
  proc logPosterior(x, y: seq[float], priors: Priors, b0, b1, sd: float): float =
    let
      like = logLikelihood(x, y, b0, b1, sd)
      prior = logPrior(priors, b0, b1, sd)
    result = like + prior

nbText: hlMd"""
# MCMC
We will use a Metropolis-Hastings algorithm to approximate the unnormalized posterior.
The steps of this algorithm are as follows:
1. Initialize arbitrary starting values for each model parameter.
2. Compute the unnormalized posterior probability density for the initialized
model parameter values given the observed data.
3. Propose a new value for one of the model parameters by randomly drawing from
a symetrical distribition centered on the present value. We will use a normal
distribution. 
4. Compute the unnormalized posterior probabity density for the proposed model
parameters values given the observed data. 
5. Compute the ratio of the proposed probability density to the previous
probability density. $ \alpha = \frac{P(\beta_{0}\prime, \beta_{1}\prime, \tau\prime | Data)}{P(\beta_{0}, \beta_{1}, \tau | Data)} $
This is called the acceptance ratio. 
6. All proposals with greater probability than the current state are accepted.
So a proposeal is accepted if the acceptance ratio is greater than 1. If the
acceptance ratio is less than 1 then it is accepted with probability \alpha. In practice we can make a
random draw from a uniform distribution ranging from 0 to 1 and accept proposals
anytime the acceptance ratio is less than the random uniform variate, $ \alpha < r \sim Uniform(0, 1)$. 
7. If a proposal is accepted then we will update the parameter in our model with
a new state. Otherwise the state will remain the same as before. 
8. We then repeat steps 3-7 until reaching a desired number of iterations that
we believe give us an adequate sample from the unnormalized posterior distribution. 

Note: When proposing values for $\tau$ from a normal distribution. It is possible for
proposals to be less than one. However, the gamma prior probability distribution
ranges from 0 to infinity meaning proposals of less than one are not valid and must
be rejected. Fortunately, this approach still gives us a proper sample of the targeted unnormalized posterior
probability distribution.

"""

nbCode:
  type
    MCMC = object
      x: seq[float]
      y: seq[float]
      nSamples: int
      priors: Priors
      propSd: float

    Samples = object
      n: int
      b0: seq[float]
      b1: seq[float]
      sd: seq[float]

  proc run(m: MCMC, b0Start, b1Start, sdStart: float): Samples =
    var
      b0Samples = newSeq[float](m.nSamples)
      b1Samples = newSeq[float](m.nSamples)
      sdSamples = newSeq[float](m.nSamples)
      logProbs = newSeq[float](m.nSamples)
    b0Samples[0] = b0Start
    b1Samples[0] = b1Start
    sdSamples[0] = sdStart
    logProbs[0] = logPosterior(m.x, m.y, m.priors, b0Start, b1Start, sdStart)

    for i in 1..<m.nSamples:
      let
        b0Proposed = gauss(b0Samples[i-1], m.propSd)
        b1Proposed = gauss(b1Samples[i-1], m.propSd)
        sdProposed = gauss(sdSamples[i-1], m.propSd)
      if sdProposed > 0.0:
        var
          logProbProposed = logPosterior(m.x, m.y, m.priors, b0Proposed, b1Proposed, sdProposed)
          ratio = exp(logProbProposed - logProbs[i-1])
        if rand(1.0) < ratio:
          b0Samples[i] = b0proposed
          b1Samples[i] = b1proposed
          sdSamples[i] = sdproposed
          logProbs[i] = logProbProposed
        else:
          b0Samples[i] = b0Samples[i-1]
          b1Samples[i] = b1Samples[i-1]
          sdSamples[i] = sdSamples[i-1]
          logProbs[i] = logProbs[i-1]
      else:
        b0Samples[i] = b0Samples[i-1]
        b1Samples[i] = b1Samples[i-1]
        sdSamples[i] = sdSamples[i-1]
        logProbs[i] = logProbs[i-1]
    result = Samples(n:m.nSamples, b0:b0Samples, b1:b1Samples, sd:sdSamples)

nbText: hlMd"""
Let's use this code to generate 100,000 samples. We'll cheat a bit and use the parameters
that the data were simulated under as starting values to speed things up. A standard deviation of 0.1
seems to work pretty well for the proposal distribution of each parameter.
"""

nbCode:
  var
    mcmc = MCMC(x:x, y:y, nSamples:100000, priors:priors, propSd:0.1)
    samples = mcmc.run(0.0, 1.0, 1.0)

nbText: hlMd"""
In some analyses, the posterior probability distribution could be multimodal
which might make the MCMC chain sensitive to the starting value as it may get stuck
in a local optimum and not sample from the full posterior distribtion. It is therefore
a good idea to acquire multiple samples with different starting values to see if they
converge on the same parameter estimates. Here we will run our MCMC one more time
with some different starting values
"""

nbCode:
  var samples2 = mcmc.run(0.2, 1.01, 1.1)

nbText: hlMd"""
# Trace plots
We can get a sense for how well our mcmc performed and therefore gain some
sense for how good our estimates might be by looking at the trace plots. Trace plots
show the parameter values stored during each step in the mcmc chain. Either
the accepted proposal value or the previous value if the proposal was rejected. Trace
plots can be an unreliable indicator of mcmc performance so it is a good
idea to assess it with other strategies as well.
"""

nbCode:
  import std/strformat

  proc plotTraces(samples: seq[Samples], prefix: string) =
    var
      sample = newSeq[seq[int]](samples.len)
      chain = newSeq[seq[int]](samples.len)
    for i in 0 ..< samples.len:
      sample[i] = toSeq(1 .. samples[i].n)
      chain[i] = repeat(i+1, samples[i].n )
    var
      df = toDf({
        "sample": concat(sample),
        "chain": concat(chain),
        "b0": concat(map(samples, proc(x: Samples): seq[float] = x.b0)),
        "b1": concat(map(samples, proc(x: Samples): seq[float] = x.b1)),
        "sd": concat(map(samples, proc(x: Samples): seq[float] = x.sd))
      })
    ggplot(df, aes(x="sample", y="b0")) +
      geom_line(aes(color="chain")) +
      ggsave(fmt"{prefix}b0.png")

    ggplot(df, aes(x="sample", y="b1")) +
      geom_line(aes(color="chain")) +
      ggsave(fmt"{prefix}b1.png")

    ggplot(df, aes(x="sample", y="sd")) +
      geom_line(aes(color="chain")) +
      ggsave(fmt"{prefix}sd.png")

  plotTraces(@[samples, samples2], "images/trace-")

nbImage("images/trace-b0.png")
nbImage("images/trace-b1.png")
nbImage("images/trace-sd.png")

nbText: hlMd"""
# Burnin
Initially the mcmc chain may spend time exploring unlikely regions of
parameter space. We can get a better approximation of the posterior if we
exclude these early steps in the chain. These excluded samples are referred to
as the burnin. A burnin of 10% seems to be more than enough with our informative priors
and starting values.
"""

nbCode:
  proc burn(samples: Samples, p: float): Samples =
    var
      burnIx = (samples.n.float * p).ceil.int
      n = samples.n - burnIx
      b0 = samples.b0[burnIx..^1]
      b1 = samples.b1[burnIx..^1]
      sd = samples.sd[burnIx..^1]
    result = Samples(n:n, b0:b0, b1:b1, sd:sd)

  var
    burnin1 = burn(samples, 0.1)
    burnin2 = burn(samples2, 0.1)

nbText: hlMd"""
# Histograms
Now that we have our post burnin samples, let's see what our posterior probability
distributions look like for each model paramter.
"""

nbCode:
  proc plotHistograms(samples: seq[Samples], prefix: string) =
    var chain = newSeq[seq[int]](samples.len)
    for i in 0 ..< samples.len:
      chain[i] = repeat(i+1, samples[i].n )
    var
      df = toDf({
        "chain": concat(chain),
        "b0": concat(map(samples, proc(x: Samples): seq[float] = x.b0)),
        "b1": concat(map(samples, proc(x: Samples): seq[float] = x.b1)),
        "sd": concat(map(samples, proc(x: Samples): seq[float] = x.sd))
      })
    ggplot(df, aes(x="b0", fill="chain")) +
      geom_histogram(position="identity", alpha=some(0.5)) +
      ggsave(fmt"{prefix}b0.png")

    ggplot(df, aes(x="b1", fill="chain")) +
      geom_histogram(position="identity", alpha=some(0.5)) +
      ggsave(fmt"{prefix}b1.png")

    ggplot(df, aes(x="sd", fill="chain")) +
      geom_histogram(position="identity", alpha=some(0.5)) +
      ggsave(fmt"{prefix}sd.png")

  plotHistograms(@[burnin1, burnin2], "images/hist-")

nbImage("images/hist-b0.png")
nbImage("images/hist-b1.png")
nbImage("images/hist-sd.png")

nbText: hlMd"""
# Posterior Summarization
It's always great to visualize your results. But it's also useful to calculate some
summary statistics for the posterior. There are several different ways you could
do this.

## Combine Chains
Before we summarize the posterior. Let's combine the samples into one.
Since we have determined that our MCMC is performing well, we can be confident
that each post burnin sample is a sample of the same distribution.
"""

nbCode:
  proc concat(samples: seq[Samples]): Samples =
    var
      n =  concat(map(samples, proc(x: Samples): int = x.n))
      b0 = concat(map(samples, proc(x: Samples): seq[float] = x.b0))
      b1 = concat(map(samples, proc(x: Samples): seq[float] = x.b1))
      sd = concat(map(samples, proc(x: Samples): seq[float] = x.sd))
    result = Samples(n:sum(n), b0:b0, b1:b1, sd:sd)

  var burnin = concat(@[burnin1, burnin2])

nbText: hlMd"""
## Posterior means
One way to summarize the estimates of the posterior distributions is to simply calculate
the mean. Let's see how close these values are to the true values of the parameters.
 """

nbCode:
  import stats

  var
    meanB0 = mean(burnin.b0).round(3)
    meanB1 = mean(burnin.b1).round(3)
    meanSd = mean(burnin.sd).round(3)

  echo "Mean b0: ", meanB0
  echo "Mean b1: ", meanB1
  echo "Mean sd: ", meanSd

nbText: hlMd"""
## Credible Intervals
The means give us a point estimate for our parameter values but they tell us
nothing about the uncertainty of our estimates. We can get a sense for that by
looking at credible intervals. There are two widely used approaches for this,
equal tailed intervals, and highest density intervals. These will often match
each other closely when the target distribution is unimodal and symetric.
We will calculate the 89% interval for each of these below. Why 89%? Why not?
Credible interval threshold values are completely arbitrary.

### Equal Tailed Interval
In this interval, the probability of being below the interval is equal to the 
probability of being above the interval.
"""

nbCode:
  import algorithm

  proc quantile(samples: seq[float], interval: float): float =
    let
      s = sorted(samples, system.cmp[float])
      k = float(s.len - 1) * interval
      f = floor(k)
      c = ceil(k)
    if f == c:
      result = s[int(k)]
    else:
      let
        d0 = s[int(f)] * (c - k)
        d1 = s[int(c)] * (k - f)
      result = d0 + d1

  proc eti(samples: seq[float], interval: float): (float, float) =
    let
      p = (1 - interval) / 2
    let
      q0 = quantile(samples, p)
      q1 = quantile(samples, 1 - p)
    result = (q0, q1)

  var
    (b0EtiMin, b0EtiMax) = eti(burnin.b0, 0.89)
    (b1EtiMin, b1EtiMax) = eti(burnin.b1, 0.89)
    (sdEtiMin, sdEtiMax) = eti(burnin.sd, 0.89)

  echo "Eti b0: ", b0EtiMin.round(3), " - ", b0EtiMax.round(3)
  echo "Eti b1: ", b1EtiMin.round(3), " - ", b1EtiMax.round(3)
  echo "Eti sd: ", sdEtiMin.round(3), " - ", sdEtiMax.round(3)


nbText: hlMd"""
### Highest Posterior Density Interval
In this interval, all values inside of the interval have a higher probability 
density than values outside of the interval.
"""

nbCode:
  proc hdi(samples: seq[float], credMass: float): (float, float) =
    let
      sortedSamples = sorted(samples, system.cmp[float])
      ciIdxInc = int(floor(credMass * float(sortedSamples.len)))
      nCIs = sortedSamples.len - ciIdxInc
    var ciWidth = newSeq[float](nCIs)
    for i in 0..<nCIs:
      ciWidth[i] = sortedSamples[i + ciIdxInc] - sortedSamples[i]
    let
      minCiWidthIx = minIndex(ciWidth)
      hdiMin = sortedSamples[minCiWidthIx]
      hdiMax = sortedSamples[minCiWidthIx + ciIdxInc]
    result = (hdiMin, hdiMax)

  var
    (b0HdiMin, b0HdiMax) = hdi(burnin.b0, 0.89)
    (b1HdiMin, b1HdiMax) = hdi(burnin.b1, 0.89)
    (sdHdiMin, sdHdiMax) = hdi(burnin.sd, 0.89)

  echo "Hdi b0: ", b0HdiMin.round(3), " - ", b0HdiMax.round(3)
  echo "Hdi b1: ", b1HdiMin.round(3), " - ", b1HdiMax.round(3)
  echo "Hdi sd: ", sdHdiMin.round(3), " - ", sdHdiMax.round(3)

nbText: hlMd"""
# Standardize Data
The $\beta_{0}$ (intercept) and $\beta_{1}$ (slope) parameters of a linear model
present a bit of a challenge for MCMC because believable values for them are
tightly correlated. This means that a lot proposed values will be rejected and the
chain will not move efficiently. An easy way to get around this problem is
to standardize our data by rescaling them relative to their mean and standard deviation.

$$ \zeta_{x_{i}} = \frac{x_{i} - \bar{x}}{SD_{x}} $$
$$ \zeta_{y_{i}} = \frac{y_{i} - \bar{y}}{SD_{y}} $$
"""

nbCode:
  var
    xSt = newSeq[float](n)
    ySt = newSeq[float](n)
    xMean = mean(x)
    xSd = standardDeviation(x)
    yMean = mean(y)
    ySd = standardDeviation(y)
for i in 0 ..< n:
  xSt[i] = (x[i] - xMean) / xSd
  ySt[i] = (y[i] - yMean) / ySd

nbText: hlMd"""
We can see that both the $y$ and $x$ values are now centered around zero and have the same scale.
"""

nbCode:
  var standardized = toDf(xSt, ySt)
  ggplot(standardized, aes(x="xSt", y="ySt")) +
    geom_point() +
    ggsave("images/st-simulated-data.png")

nbImage("images/st-simulated-data.png")

nbText: hlMd"""
We can now run the MCMC just as before with some minor changes. The standard deviation
$\tau$ for the standardized data is going to be much smaller. Let's make the prior
more informative. The standard deviation of the proposal distribution used before
would result in most proposals being rejected so we should use a smaller value
this time. Finally we should use some different starting values than before.
"""

nbCode:
  var
    st_priors = Priors(
      b0: Normal(mu:0.0, sigma:1.0),
      b1: Normal(mu:1.0, sigma:1.0),
      sd: Gamma(k:0.0035, sigma:1.0))
    st_mcmc = MCMC(x:xSt, y:ySt, nSamples:100000, priors:st_priors, propSd:0.001)
    st_samples1 = st_mcmc.run(0.0, 1.0, 0.0034)
    st_samples2 = st_mcmc.run(0.1, 1.01, 0.0036)

nbText: hlMd"""
### Convert back to original scale
To interpret these estimates we need to convert back to the original scale.
$$ \beta_{0} = \zeta_{0} SD_{y} + \bar{y} - \zeta_{1} SD_{y} \bar{x} / SD_{x} $$
$$ \beta_{1} = \zeta_{1} SD_{y} / SD_{x} $$
$$ \tau = \zeta_{\tau} * SD_{y} $$
"""

nbCode:
  proc backTransform(samples: Samples, xMean, xSd, yMean, ySd: float): Samples =
    var
      b0 = newSeq[float](samples.n)
      b1 = newSeq[float](samples.n)
      sd = newSeq[float](samples.n)
    for i in 0 ..< samples.n:
      b0[i] = samples.b0[i] * ySd + yMean - samples.b1[i] * ySd * xMean / xSd
      b1[i] = samples.b1[i] * ySd / xSd
      sd[i] = samples.sd[i] * ySd
    result = Samples(n:samples.n, b0:b0, b1:b1, sd:sd)

  var
    st_samples_trans1 = backTransform(st_samples1, xMean, xSd, yMean, ySd)
    st_samples_trans2 = backTransform(st_samples2, xMean, xSd, yMean, ySd)

nbText: hlMd"""
# Traceplots
Let's have a look at the trace plots.
"""

nbCode:
  plotTraces(@[st_samples_trans1, st_samples_trans2], "images/trace-st-")

nbImage("images/trace-st-b0.png")
nbImage("images/trace-st-b1.png")
nbImage("images/trace-st-sd.png")

nbText: hlMd"""
It looks like more of the proposals were accepted and we have a much better
sample from the posterior.
"""

nbText: hlMd"""
# Burnin
Let's get a post burnin sample as we did before.
"""

nbCode:
  var
    st_burnin1 = burn(st_samples_trans1, 0.1)
    st_burnin2 = burn(st_samples_trans2, 0.1)

nbText: hlMd"""
# Histograms
Now we can have a look at the posterior distribution of our estimates.
"""

nbCode:
  plotHistograms(@[st_burnin1, st_burnin2], "images/hist-st-")


nbImage("images/hist-st-b0.png")
nbImage("images/hist-st-b1.png")
nbImage("images/hist-st-sd.png")

nbText: hlMd"""
These look pretty good but it's hard to know how they compare to the previous
MCMC estimates. Let's summarize the posterior to get a better idea.
"""

nbCode:

  var st_burnin = concat(@[st_burnin1, st_burnin2])

  var
    st_meanB0 = mean(st_burnin.b0).round(3)
    st_meanB1 = mean(st_burnin.b1).round(3)
    st_meanSd = mean(st_burnin.sd).round(3)

  echo "Mean b0: ", meanB0
  echo "Mean b1: ", meanB1
  echo "Mean sd: ", meanSd

  var
    (st_b0EtiMin, st_b0EtiMax) = eti(st_burnin.b0, 0.89)
    (st_b1EtiMin, st_b1EtiMax) = eti(st_burnin.b1, 0.89)
    (st_sdEtiMin, st_sdEtiMax) = eti(st_burnin.sd, 0.89)

  echo "Eti b0: ", st_b0EtiMin.round(3), " - ", st_b0EtiMax.round(3)
  echo "Eti b1: ", st_b1EtiMin.round(3), " - ", st_b1EtiMax.round(3)
  echo "Eti sd: ", st_sdEtiMin.round(3), " - ", st_sdEtiMax.round(3)

  var
    (st_b0HdiMin, st_b0HdiMax) = hdi(st_burnin.b0, 0.89)
    (st_b1HdiMin, st_b1HdiMax) = hdi(st_burnin.b1, 0.89)
    (st_sdHdiMin, st_sdHdiMax) = hdi(st_burnin.sd, 0.89)

  echo "Hdi b0: ", st_b0HdiMin.round(3), " - ", st_b0HdiMax.round(3)
  echo "Hdi b1: ", st_b1HdiMin.round(3), " - ", st_b1HdiMax.round(3)
  echo "Hdi sd: ", st_sdHdiMin.round(3), " - ", st_sdHdiMax.round(3)


nbText: hlMd"""
In comparison to the previous mcmc results shown below, it looks like the standardized
analysis was actually pretty similar. But we can have greater confidence after
using the standardized analysis because we got a better posterior sample.
"""

nbCode:
  echo "Mean b0: ", meanB0
  echo "Mean b1: ", meanB1
  echo "Mean sd: ", meanSd

  echo "Eti b0: ", b0EtiMin.round(3), " - ", b0EtiMax.round(3)
  echo "Eti b1: ", b1EtiMin.round(3), " - ", b1EtiMax.round(3)
  echo "Eti sd: ", sdEtiMin.round(3), " - ", sdEtiMax.round(3)

  echo "Hdi b0: ", b0HdiMin.round(3), " - ", b0HdiMax.round(3)
  echo "Hdi b1: ", b1HdiMin.round(3), " - ", b1HdiMax.round(3)
  echo "Hdi sd: ", sdHdiMin.round(3), " - ", sdHdiMax.round(3)

nbText: hlMd"""
# Final Note
We could have simply and more efficiently done all of this using least squares regression.
However the Bayesian approach allows us to very easily and intuitively express
uncertainty about our estimates and can be easily extended to much more complex
models for which there are not such simple solutions. We could also incorporate prior
knowledge or assumptions in a way not possible with frequentist approaches.
The exercise above provides a starting point for this and shows just how easy it is to do with Nim!
"""

nbSave