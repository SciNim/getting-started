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

### [Arraymancer](https://github.com/mratsim/arraymancer)

[Arraymancer](https://github.com/mratsim/arraymancer) provides a generic `Tensor[T]` type,
similar to a Numpy `ndarray`. On top it defines operations from indexing, broadcasting
and apply/map/fold/reduce operations to linear algebra and much more:
"""
nbCode:
  import arraymancer
  let t = arange(0, 9).reshape([3, 3]) ## typical tensor constructors
  echo t +. 1 ## broadcasting operations
nbText: """

### [Neo](https://github.com/andreaferretti/neo)

[Neo](https://github.com/andreaferretti/neo) provides primitives for linear algebra. This means
it implements vectors and matrices, either with static or dynamic sizes.

### [Datamancer](https://github.com/scinim/datamancer)

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

### [NimData](https://github.com/bluenote10/nimdata)

[NimData](https://github.com/bluenote10/nimdata) provides another `DataFrame` implementation,
which - compared to Datamancer - has a stricter CT safety focus. Its implementation is
row based and the `DataFrame` type is determined at compile time. Operations are built on top
of iterators for lazy evaluation.

### [Flambeau](https://github.com/scinim/flambeau)

[Flambeau](https://github.com/scinim/flambeau) is a [libtorch](https://pytorch.org/) wrapper. Thus,
it provides both a `Tensor[T]` type (and the expected associated operations) as well as
being a machine learning library.

## Data visualization

There are multiple libraries for data visualization ("plotting") available,
each with their own focus and thus pros and cons.

Beyond the libraries listed in this section, keep in mind that your favorite
Python, Julia and R plotting library is only a [nimpy](https://github.com/yglukhov/nimpy),
[nimjl](https://github.com/Clonkk/nimjl) and [Rnim](https://github.com/SciNim/Rnim) call away!

### [ggplotnim](https://github.com/Vindaar/ggplotnim)

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

### [nim-plotly](https://github.com/SciNim/nim-plotly)

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

### Other plotting libraries

- [asciigraph](https://github.com/KeepCoolWithCoolidge/asciigraph) ⇐ plots data using unicode symbols to draw
  pretty graphs in the terminal
- [gr.nim](https://github.com/mantielero/gr.nim) ⇐ wrapper of the [GR visualization framework](https://gr-framework.org/)

## Numerical algorithms

Numerical algorithms for integration, interpolation, (numerical) differentiation and
solving differential equations are of course fundamental for scientific computing.

### [Numericalnim](https://github.com/SciNim/numericalnim)

[Numericalnim](https://github.com/SciNim/numericalnim) is *the* most comprehensive
library for numerical algorithms in Nim. It contains multiple algorithms each for the
topics mentioned above.

See for example the tutorial for numerical integration [here](https://scinim.github.io/getting-started/numerical_methods/integration1d.html)
to get acquainted with the basic usage of the library.

### [Polynumeric](https://github.com/SciNim/polynumeric)

For purely polynomial operations, the [polynumeric](https://github.com/SciNim/polynumeric)
is useful. It provides all common operations on polynomials one might need (integration,
differentiation, root finding, fitting a polynomial and more). The advantage is that
polynomial operations are simply and can be solved analytically (more efficient & more accurate
than performing the equivalent operation using a numerical algorithm).

## Optimization

Optimization (possibly non-linear) problems are a problem domain large enough to deserve
their own section beyond the "numerical algorithm" section.

### [Numericalnim](https://github.com/SciNim/numericalnim)

[Numericalnim](https://github.com/SciNim/numericalnim) itself also recently added algorithms
for non-linear optimization. These include Levenberg-Marquardt for non-linear curve fitting
and (L)BFGS for general optimization problems.

### [fitl](https://github.com/c-blake/fitl)

[fitl](https://github.com/c-blake/fitl) contains a pure Nim linear least squares solver (so
no LAPACK dependency!) and provides many goodness-of-fit tests.

### [nimnlopt](https://github.com/Vindaar/nimnlopt)

[nimnlopt](https://github.com/Vindaar/nimnlopt) is a wrapper of the [NLopt](https://nlopt.readthedocs.io/en/latest/)
C library. It includes a large number of algorithms for non-linear optimization problems.
The algorithms can be separated into 4 different classes:
- gradient & non gradient based methods
- global & local methods
where each algorithm is either local or global and either needs derivatives or does not.

It supports custom constraints for the optimization and arbitrary bounds for each parameter.

### [nim-mpfit](https://github.com/Vindaar/nim-mpfit)

[nim-mpfit](https://github.com/Vindaar/nim-mpfit) is a wrapper of the C library [cmpfit](https://pages.physics.wisc.edu/~craigm/idl/cmpfit.html),
which is an implementation of the Levenberg-Marquardt algorithm for non-linear least squares
problems (i.e. non-linear curve fitting).

### [gsl-nim](https://github.com/YesDrX/gsl-nim)

A wrapper for the [GNU Scientific Library](https://www.gnu.org/software/gsl/), which probably satisfies
all your numerical optimization needs (and much more), if you can live with the GSL dependence and raw C API.

## (Binary) data storage & serialization libraries

- [nimhfd5](https://github.com/Vindaar/nimhdf5) ⇐ high level bindings for the HDF5 library
- [netcdf](https://github.com/SciNim/netcdf) ⇐ wrapper for NetCDF library
- [mcpl](https://github.com/SciNim/mcpl) ⇐ wrapper for MCPL library
- Arrow
  - [freccia](https://github.com/SciNim/freccia) ⇐ pure Nim library for Apache Arrow format
  - [nimarrow_glib](https://github.com/emef/nimarrow_glib) ⇐ wrapper of libarrow
- [nio](https://github.com/c-blake/nio) ⇐ also includes operations for binary data handling
- [nimcfitsio](https://github.com/ziotom78/nimcfitsio) ⇐ wrapper for the CFITSIO library, typically used
  in astronomy
- [nim-teafiles](https://github.com/andreaferretti/nim-teafiles) ⇐ library to read [TeaFiles](http://discretelogics.com/teafiles/),
  a format for fast read/write access to time series data
- [CSVtools](https://github.com/andreaferretti/csvtools) ⇐ library for typed iterators on CSV files
- [DuckDB](https://github.com/ayman-albaz/nim-duckdb) ⇐ DuckDB wrapper for Nim. DuckDB is a DB focused on fast data analysis

## Linear algebra

A list of libraries for linear algebra operations. These libraries typically provide their own matrix and vector
types and define common (and not so common) operations on them.

- [Neo](https://github.com/andreaferretti/neo) ⇐ linear algebra library with support for dense and sparse
  matrices. Wraps BLAS & LAPACK and also has GPU support
- [Manu](https://github.com/planetis-m/manu) ⇐ pure Nim library for operations on real, dense matrices (solving linear
  equations, determinants, matrix inverses & decompositions, ...)
- [Arraymancer](https://github.com/mratsim/arraymancer) ⇐ Arraymancer also provides many linear algebra routines
- [gsl-nim](https://github.com/YesDrX/gsl-nim) ⇐ GSL provides
  [many linear algebra](https://www.gnu.org/software/gsl/doc/html/linalg.html) routines

## Algebra

- [emmy](https://github.com/andreaferretti/emmy) ⇐ Algebraic structures and operations on them
- [nim-algebra](https://github.com/MichalMarsalek/nim-algebra) ⇐ implements many routines for rings, fields and groups

## Symbolic operations

Libraries dealing with symbolic instead of numeric operations.

- [astgrad](https://github.com/SciNim/astgrad) ⇐ symbolic derivatives based on Nim AST
- [symbolicnim](https://github.com/hugogranstrom/symbolicnim) ⇐ pure Nim library for symbolic computations
- [symengine](https://github.com/SciNim/symengine.nim) ⇐ wrapper for C++ library for symbolic computations

## Number types

These libraries all provide specific data types suited to certain kind of operations.

- decimal libraries
  - [nim-decimal](https://github.com/status-im/nim-decimal) ⇐ decimal library wrapping C lib `mpdecimal`
  - [decimal128](https://github.com/JohnAD/decimal128) ⇐ pure Nim decimal library, missing some features
- multi-precision integers (bigints)
  - [bignum](https://github.com/SciNim/bignum) ⇐ wrapper of GMP providing arbitrary precision ints & rationals, does not wrap `mpfr` (so no multi precision floats)
  - [bigints](https://github.com/nim-lang/bigints) ⇐ pure Nim bigint library
  - [theo](https://github.com/SciNim/theo) ⇐ optimized bigint library, WIP
- [fpn](https://gitlab.com/lbartoletti/fpn) ⇐ fixed point number library in pure Nim
- [stdlib rationals](https://nim-lang.github.io/Nim/rationals.html) ⇐ Nim standard library module  for rational numbers
- [stdlib complex](https://nim-lang.github.io/Nim/complex.html) ⇐ Nim standard library module for complex numbers

## Statistics, sampling and random number generation

- [statistical-tests](https://github.com/ayman-albaz/statistical-tests)
- [linear-models](https://github.com/ayman-albaz/linear-models)
- [distributions](https://github.com/ayman-albaz/distributions)
- [stdlib stats](https://nim-lang.github.io/Nim/stats.html) ⇐ basic statistics module from the stdlib. Supports moments up to
  kurtosis & provides basic regression support
- [alea](https://github.com/andreaferretti/alea) ⇐ library for sampling from many different distribiutons. Allows to wrap custom (e.g. stdlib) RNGs
- [sitmo](https://github.com/jxy/sitmo) ⇐ Nim implementation of the Sitmo parallel RNG
- [stdlib random](https://nim-lang.github.io/Nim/random.html) ⇐ random number generation of the Nim standard library
- [nim-random](https://github.com/oprypin/nim-random) ⇐ alternative to the Nim stdlib random number library
- [nim-mentat](https://github.com/ruivieira/nim-mentat) ⇐ implements exponentially weighted moving averages

## Machine learning

- [Flambeau](https://github.com/SciNim/flambeau) ⇐ as a wrapper to [libtorch](https://pytorch.org/cppdocs/installing.html) provides
  access to state-of-the-art ML features
- [Arraymancer](https://github.com/mratsim/arraymancer) ⇐ Arraymancer implements a DSL to define neural networks
  (see the [examples](https://github.com/mratsim/Arraymancer/tree/master/examples)) and provides other, more primitive
  ML tools (PCA, ...)
- [exprgrad](https://github.com/can-lehmann/exprgrad) ⇐ Experimental deep learning framework, based on an
  easily extensible LLVM compiled differentiable programming language
- [DecisionTreeNim](https://github.com/Michedev/DecisionTreeNim) ⇐ implements decision trees & random forests

## Natural language processing

- [tome](https://github.com/dizzyliam/tome) ⇐ provides tokenization and parts of speech (POS) tagging
- [word2vec](https://github.com/treeform/word2vec) ⇐ [Word2vec](https://en.wikipedia.org/wiki/Word2vec) implementation in Nim
- [fastText](https://github.com/Nim-NLP/fastText) ⇐ library to perform predictions of [fastText](https://github.com/facebookresearch/fastText) models
- [scim](https://github.com/xflywind/scim) ⇐ library for helpful tools for speech recognition based on arraymancer

## Spatial data structures, distance measures & clustering algorithms

- [kdtree](https://github.com/jblindsay/kdtree) ⇐ k-d tree implementation in pure Nim
- [RTree](https://github.com/stefansalewski/RTree) ⇐ R- and R*-Tree implementations in pure Nim
- [QuadtreeNim](https://github.com/Nycto/QuadtreeNim) ⇐ Quadtree implementation implementation in pure Nim
- [distances](https://github.com/ayman-albaz/distances) ⇐ library to compute distances under different metrics
  with support for standard sequences, arraymancer & neo types
- [arraymancer](https://github.com/mratsim/arraymancer) ⇐ arraymancer contains a k-d tree implementation, multiple
  distance metrics (incl. user defined custom metrics) plus k-means & DBSCAN clustering algorithms
- [spacy](https://github.com/treeform/spacy) ⇐ collection of different spatial data structures
- [DelaunayNim](https://github.com/Nycto/DelaunayNim) ⇐ library to compute the [Delaunay triangulation](https://en.wikipedia.org/wiki/Delaunay_triangulation) of a set of points
- [nim-mentat](https://github.com/ruivieira/nim-mentat) ⇐ implements Balanced Box-Decomposition trees

## Special functions

These libraries implement different [special functions](https://en.wikipedia.org/wiki/Special_functions).

- [stdlib math](https://nim-lang.github.io/Nim/math.html) ⇐ The Nim standard library `math` module contains all libraries
  you find in `math.h`.
- [spfun](https://github.com/c-blake/spfun) ⇐ library for many special functions used in stats, physics, ...
- [gsl-nim](https://github.com/YesDrX/gsl-nim) ⇐ The GSL probably provides
  [any special function](https://www.gnu.org/software/gsl/doc/html/specfunc.html) you may need
- [special-functions](https://github.com/ayman-albaz/special-functions) ⇐ contains many special functions, which are not part of the stdlib module

## FFT

- [nimfftw3](https://github.com/SciNim/nimfftw3) ⇐ FFTW3 wrapper
- [impulse](https://github.com/SciNim/impulse) ⇐ pocket FFT wrapper, in principle a repository for signal processing primitives
- [kissFFT](https://github.com/m13253/nim-kissfft) ⇐ kissFFT wrapper

## Primitive compute wrappers

- [nimcuda](https://github.com/andreaferretti/nimcuda)
- [nimlapack](https://github.com/andreaferretti/nimlapack)
- [nimblas](https://github.com/andreaferretti/nimblas)
- [nimcl](https://github.com/andreaferretti/nimcl)

## Multithreading & asynchronous processing

- [weave](https://github.com/mratsim/weave)
- [taskpools](https://github.com/status-im/nim-taskpools)
- [threadpools](https://github.com/yglukhov/threadpools) ⇐ Custom threadpool implementation
- [threading](https://github.com/nim-lang/threading) ⇐ New pieces for multithreading in times of ARC/ORC
- [asynctools](https://github.com/cheatfate/asynctools) ⇐ Various async tools for usage with Nim's stdlib `async` macro
- [asyncthreadpool](https://github.com/yglukhov/asyncthreadpool) ⇐ An awaitable threadpool implementation

## Biology

- [hts-nim](https://github.com/brentp/hts-nim) ⇐ A wrapper for [htslib](https://github.com/samtools/htslib) for Nim for parsing of
  genomics data files
- [bionim](https://github.com/SciNim/bionim) ⇐  collection of data structures and algorithms for bioinformatics
- [bio](https://github.com/SciNim/bio) ⇐ a library for working with biological sequences

## Physics & astronomy

- [unchained](https://github.com/SciNim/Unchained) ⇐ library for CT checking of physical units and
  automatic conversion between units
- [qex](https://github.com/jcosborn/qex/) ⇐ lattice QCD library
- [mclimit](https://github.com/SciNim/mclimit) ⇐ Nim port of the ROOT TLimit class for confidence level computations (limits) for experiments with small statistics
- [nim-constants](https://github.com/SciNim/nim-constants) ⇐ contains many physical and mathematical constants
- [astroNimy](https://github.com/dizzyliam/astroNimy) ⇐ astronomical image processing library
- [orbits](https://github.com/treeform/orbits) ⇐ library for orbital mechanics calculations
- [nim-root](https://github.com/watson-ij/nim-root) ⇐ partial wrapper for [CERN's ROOT](https://root.cern.ch)
- [MDevolve](https://github.com/jxy/MDevolve) ⇐ integrator framework for molecular dynamic evolutions
- [polypbren](https://github.com/guibar64/polypbren) ⇐ program to compute renormalized parameters of charged colloids

## Mathematics

- [perms-nim](https://github.com/remigijusj/perms-nim) ⇐ library for permutation group calculations and factorization algorithms

## Other useful libraries

- [scinim](https://github.com/SciNim/scinim) ⇐ library of general scientific things that are
  either primitives or too small to have their own library
- [Measuremancer](https://github.com/SciNim/Measuremancer) ⇐ library for automatic error propagation
  of measurement uncertainties
- [gsl-nim](https://github.com/YesDrX/gsl-nim) ⇐ wrapper for GSL (GNU Scientific Library)
- [nim-opencv](https://github.com/dom96/nim-opencv) ⇐ Nim wrapper for [OpenCV](https://en.wikipedia.org/wiki/OpenCV)
- [zero-functional](https://github.com/zero-functional/zero-functional) ⇐ library for zero cost chaining of
  functional primitves (map, apply, fold, ...). Fuses multiple operations into a single loop.
- [iterrr](https://github.com/hamidb80/iterrr) ⇐ another library for zero cost chaining, similar to `zero-functional`. Aims to be
  easier to extend.
- [flower](https://github.com/dizzyliam/flower) ⇐ pure Nim bloom filter, probabilistic data structure to check if
  elements are in a set ("possibly in set" vs. "definitely not in set"). Supports arbitrary Nim types in single filter.
- pattern matching:
  - [pattern matching in fusion](https://github.com/nim-lang/fusion/blob/master/src/fusion/matching.rst) ⇐ pattern
    matching for Nim. Possibly the most feature rich pattern matching library for Nim. Future developments might
    be found [here](https://github.com/haxscramper/hmatching)
  - [patty](https://github.com/andreaferretti/patty)
  - [gara](https://github.com/alehander92/gara)
- [Synthesis](https://github.com/mratsim/Synthesis) ⇐ DSL to generate statically checked state machines
- [jupyternim](https://github.com/stisa/jupyternim) ⇐ Jupyter kernel for Nim
- [cligen](https://github.com/c-blake/cligen) ⇐ elegant library to write CLI interfaces
- [LatexDSL](https://github.com/Vindaar/LatexDSL) ⇐ DSL to generate CT checked latex strings, supporting Nim variable interpolation
- [nim-mathexpr](https://github.com/Yardanico/nim-mathexpr) ⇐ mathematical string expression evaluator library
- [nim-pari](https://codeberg.org/BarrOff/nim-pari) ⇐ wrapper for the [PARI](https://pari.math.u-bordeaux.fr/) C library underlying
  the PARI/GP computer algebra system
- [memo](https://github.com/andreaferretti/memo) ⇐ macro library to allow memoization of function calls (automatic caching of
  function calls)
- [forematics](https://github.com/treeform/forematics) ⇐ Nim implementation of a [Metamath](http://us.metamath.org/) verifier
- [DeepLearningNim](https://github.com/Niminem/DeepLearningNim) ⇐ example of building a DQN with arraymancer

## Educational resources

- [nim-bayes](https://github.com/kerrycobb/nim-bayes) ⇐ Tutorial about Bayesien Inference of a linear model in Nim

## Language bindings

First of all Nim itself of course provides direct support to wrap C and C++ libraries
using its FFI. See the Nim manual [here](https://nim-lang.github.io/Nim/manual.html#foreign-function-interface)
for an introduction to the C / C++ FFI.

For more details on how to use the language specific bindings, see the section
about it [here](https://scinim.github.io/getting-started/external_language_integration/index.html)

### Tools to wrap C / C++

- [c2nim](https://github.com/nim-lang/c2nim) ⇐ the default Nim tool to generate Nim wrappers of C header files
- [futhark](https://github.com/PMunch/futhark) ⇐ automatic imports of C header files in Nim code
- [nimterop](https://github.com/nimterop/nimterop) ⇐ library to simplify wrapping of C/C++ using [tree-sitter](http://tree-sitter.github.io/tree-sitter/)

### Julia

- [nimjl](https://github.com/Clonkk/nimjl)

### Python

- [nimpy](https://github.com/yglukhov/nimpy)

### R

- [Rnim](https://github.com/SciNim/Rnim)

"""

nbSave
