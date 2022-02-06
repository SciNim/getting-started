import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# Overview of the scientific computing ecosystem

This chapter aims to provide a rough overview of the ecosystem for scientific computing
with the aim to present the available packages with an overview of what they can be
used for.

Note that due to the way this page is laid out, some packages might appear multiple times
under different sections.

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

## What am I

- scinim
- measuremancer
- unchained
- spfun (c-blake) (contains special functions)
- gsl bindings

## Data visualization

- ggplotnim
- nim-plotly
- gnuplot bindings

## Optimization

- nimnlopt
- nim-mpfit
- fitl (c-blake) (contains linear least squares & goodness of fit tests)

## General numerical algorithms

This includes numerical integration, interpolation, differentiation etc.

- numericalnim
- polynumeric <- operations on polynomials

## Bindings to binary data formats

- nimhfd5
- netcdf <- pure wrapper
- mcpl <- pure wrapper
- freccia
- nio <- also includes operations for binary data handling

## Symbolic operations

- astgrad
- symbolicnim
- symengine

## Numbers

- megalo
- nim-constants
- decimal library
- bignum
- nim-bigints

## FFT

- nimfftw3
- impulse (pocket FFT)
- kissFFT

## Primitive compute wrappers

- nimcuda
- nimlapack
- nimblas
- nimcl

## Multithreading

- weave
- taskpools
- threadpools (yglukhov)

## Random number generation

- alea

## Biology specific

- biology libraries, ask brentp for some input
- bionim

## Physics

- qex <- lattice QCD library

## Other useful libraries
- zero-functional
- pattern matching stuff

## Language bindings

First of all Nim itself of course provides direct support to wrap C and C++ libraries
using its FFI. See the Nim manual [here](https://nim-lang.github.io/Nim/manual.html#foreign-function-interface)
for an introduction to the C / C++ FFI.

## Julia

- nimjl

## Python

- nimpy

## R

- rnim


"""

nbSave
