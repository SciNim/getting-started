import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# Overview of the scientific computing ecosystem

This chapter aims to provide a rough overview of the ecosystem for scientific computing
with the aim to present the available packages with an overview of what they can be
used for.

In general, keep the [Nimble directory](https://nimble.directory/) handy to search for
Nim packages from your browser.

Note that due to the way this page is laid out, some packages might appear multiple times
under different sections.

Further: if you feel any existing library is missing on this page, *please* either create
a PR to this page, open an issue or simply write a message in the Matrix/Discord Nim science
channel!

## Fundamental data handling libraries

The libraries listed here all provide basic data types that are helpful in general.

### Arraymancer

[Arraymancer](https://github.com/mratsim/arraymancer) provides a generic `Tensor[T]` type,
similar to a Numpy `ndarray`. On top it defines operations from indexing, broadcasting
and apply/map/fold/reduce operations to linear algebra and much more:
"""
nbCode:
  import arraymancer
  let t = arange(0, 9).reshape([3, 3]) ## typical tensor constructors
  echo t +. 1 ## broadcasting operations
nbText: """

### Neo

[Neo](https://github.com/andreaferretti/neo) provides primitives for linear algebra. This means
it implements vectors and matrices, either with static or dynamic sizes.

### Datamancer

[Datamancer](https://github.com/scinim/datamancer) builds on top of Arraymancer to provide
a `DataFrame` runtime based implementation. Runtime based means the types of columns are
determined at runtime instead of compile time (e.g. via a schema). The focus is on column
based operations.
"""
nbCode:
  import datamancer
  let df = seqsToDf({"Age" : @[24, 32, 53], "Name" : @["Foo", "Bar", "Baz"]})
  echo df

nbText: """

### NimData

[NimData](https://github.com/bluenote10/nimdata) provides another `DataFrame` implementation,
which - compared to Datamancer - has a stricter CT safety focus. Its implementation is
row based and the `DataFrame` type is determined at compile time. Operations are built on top
of iterators for lazy evaluation.

## Flambeau

[Flambeau](https://github.com/scinim/flambeau) is a [libtorch](https://pytorch.org/) wrapper. Thus,
it provides both a general `Tensor[T]` type (and the expected associated operations) as well as
being a machine learning library.

## Other libraries

- [scinim](https://github.com/SciNim/scinim) <- library of general scientific things that are
  either primitives or too small to have their own library
- [Measuremancer](https://github.com/SciNim/Measuremancer) <- library for automatic error propagation
  of measurement uncertainties
- [unchained](https://github.com/SciNim/Unchained) <- library for CT checking of physical units and
  automatic conversion between units
- [spfun](https://github.com/c-blake/spfun) <- contains many special function
- gsl bindings
  - [gsl-nim](https://github.com/YesDrX/gsl-nim) <- wrapper for GSL

## Data visualization

There are multiple libraries for data visualization ("plotting") available,
each with their own focus and thus pros and cons.

Beyond the libraries listed in this section, keep in mind that your favorite
Python, Julia and R plotting library is only a [nimpy](https://github.com/yglukhov/nimpy),
[nimjl](https://github.com/Clonkk/nimjl) and [Rnim](https://github.com/SciNim/Rnim) call away!

### ggplotnim

[ggplotnim](https://github.com/Vindaar/ggplotnim) is a pure Nim library for data visualization
that is highly inspired by [ggplot2](https://ggplot2.tidyverse.org) for R. It is a library using
the "Grammar of Graphics" approach to build visualizations. Inputs are given as a `Datamancer`
`DataFrame` and plot is built from different "geom" layers.

Use this library if you want static graphics, suitable for scientific publications.

"""
nbCode:
  import ggplotnim
  let x = @[1, 2, 3, 4]
  let y = @[2, 4, 8, 16]
  let dfP = toDf({"x" : x, "y" : y}) ## toDf(x, y) would use the identifiers as keys, i.e. equivalent
  ggplot(dfP, aes("x", "y")) + geom_point() + ggsave("images/simple_points.pdf")

nbText: """
Also see the introduction to data visualization using `ggplotnim` [here](https://scinim.github.io/getting-started/data_viz/plotting_data.html).

### nim-plotly

As the name implies [nim-plotly](https://github.com/SciNim/nim-plotly) is an interface to the
JavaScript library [plotly.js](https://plotly.com/javascript/basic-charts/). It generates
plotly compatible JSON, which by default is inserted into an HTML file that loads the JS library.

As its essentially a data ↦ plotly JSON converter, it can easily be used to feed data to
some interactive JS program to update plots in realtime and more.

### gnuplot

There are multiple gnuplot bindings available.
- [gnuplot.nim](https://github.com/dvolk/gnuplot.nim)
- [gnuplotlib](https://github.com/planetis-m/gnuplotlib)

Both of these open a `gnuplot` process and feed data to it via `stdin`.

## Numerical algorithms

Numerical algorithms for integration, interpolation, (numerical) differentiation and
solving differential equations are of course fundamental for scientific computing.

### Numericalnim

[Numericalnim](https://github.com/SciNim/numericalnim) is *the* most comprehensive
library for numerical algorithms in Nim. It contains multiple algorithms each for the
topics mentioned above.

See for example the tutorial for numerical integration [here](https://scinim.github.io/getting-started/numerical_methods/integration1d.html)
to get acquainted with the basic usage of the library.

### Polynumeric

For purely polynomial operations, the [polynumeric](https://github.com/SciNim/polynumeric)
is useful. It provides all common operations on polynomials one might need (integration,
differentiation, root finding, fitting a polynomial and more). The advantage is that
polynomial operations are simply and can be solved analytically (more efficient & more accurate
than performing the equivalent operation using a numerical algorithm).

## Optimization

Optimization (possibly non-linear) problems are a problem domain large enough to deserve
their own section beyond the "numerical algorithm" section.

### Numericalnim

[Numericalnim](https://github.com/SciNim/numericalnim) itself also recently added algorithms
for non-linear optimization. These include Levenberg-Marquardt for non-linear curve fitting
and (L)BFGS for general optimization problems.

### fitl

[fitl](https://github.com/c-blake/fitl) contains a pure Nim linear least squares solver (so
no LAPACK dependency!) and provides many goodness-of-fit tests.

### nimnlopt

[nimnlopt](https://github.com/Vindaar/nimnlopt) is a wrapper of the [NLopt](https://nlopt.readthedocs.io/en/latest/)
C library. It includes a large number of algorithms for non-linear optimization problems.
The algorithms can be separated into 4 different classes:
- gradient & non gradient based methods
- global & local methods
where each algorithm is either local or global and either needs derivatives or does not.

It supports custom constraints for the optimization and arbitrary bounds for each parameter.

### nim-mpfit

[nim-mpfit](https://github.com/Vindaar/nim-mpfit) is a wrapper of the C library [cmpfit](https://pages.physics.wisc.edu/~craigm/idl/cmpfit.html),
which is an implementation of the Levenberg-Marquardt algorithm for non-linear least squares
problems (i.e. non-linear curve fitting).

## Binary data storage formats

- [nimhfd5](https://github.com/Vindaar/nimhdf5) <- high level bindings for the HDF5 library
- [netcdf](https://github.com/SciNim/netcdf) <- wrapper for NetCDF library
- [mcpl](https://github.com/SciNim/mcpl) <- wrapper for MCPL library
- [freccia](https://github.com/SciNim/freccia) <- Nim library for Apache Arrow format
- [nio](https://github.com/c-blake/nio) <- also includes operations for binary data handling

## Symbolic operations

- [astgrad](https://github.com/SciNim/astgrad) <- symbolic derivatives based on Nim AST
- [symbolicnim](https://github.com/hugogranstrom/symbolicnim) <- pure Nim library for symbolic computations
- [symengine](https://github.com/SciNim/symengine.nim) <- wrapper for C++ library for symbolic computations

## Numbers

- [theo](https://github.com/SciNim/theo)
- [nim-constants](https://github.com/SciNim/nim-constants) <- contains many physical constants
- decimal library
- bignum
- nim-bigints

## FFT

- [nimfftw3](https://github.com/SciNim/nimfftw3) <- FFTW3 wrapper
- [impulse](https://github.com/SciNim/impulse) <- pocket FFT wrapper
- [kissFFT](https://github.com/m13253/nim-kissfft) <- kissFFT wrapper

## Primitive compute wrappers

- [nimcuda](https://github.com/andreaferretti/nimcuda)
- [nimlapack](https://github.com/andreaferretti/nimlapack)
- [nimblas](https://github.com/andreaferretti/nimblas)
- [nimcl](https://github.com/andreaferretti/nimcl)

## Multithreading

- [weave](https://github.com/mratsim/weave)
- [taskpools](https://github.com/status-im/nim-taskpools)
- [threadpools](https://github.com/yglukhov/threadpools)

## Random number generation

- [alea](https://github.com/andreaferretti/alea) <- amazing library for random number generation

## Biology specific

- biology libraries, ask brentp for some input
- bionim

## Physics

- [qex](https://github.com/jcosborn/qex/) <- lattice QCD library

## Other useful libraries
- [zero-functional](https://github.com/zero-functional/zero-functional) <- library for zero cost chaining of
  functional primitves (map, apply, fold, ...). Fuses multiple operations into a single loop.
- [pattern matching in fusion](https://github.com/nim-lang/fusion/blob/master/src/fusion/matching.rst) <- pattern
  matching for Nim
- [cligen](https://github.com/c-blake/cligen) <- elegant library to write CLI interfaces

## Language bindings

First of all Nim itself of course provides direct support to wrap C and C++ libraries
using its FFI. See the Nim manual [here](https://nim-lang.github.io/Nim/manual.html#foreign-function-interface)
for an introduction to the C / C++ FFI.

For more details on how to use the language specific bindings, see the section
about it [here](https://scinim.github.io/getting-started/external_language_integration/index.html)

## Julia

- [nimjl](https://github.com/Clonkk/nimjl)

## Python

- [nimpy](https://github.com/yglukhov/nimpy)

## R

- [Rnim](https://github.com/SciNim/Rnim)

"""

nbSave
