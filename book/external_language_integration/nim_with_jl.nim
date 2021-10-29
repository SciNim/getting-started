import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# Using Julia with Nim

In this tutorial, we explore how to use [Nimjl](https://github.com/Clokk/nimjl) to integrate Python code with Nim.

## What is Julia ?

Julia is a dynamicalyl typed scripting language designed for high performance; it compiles to efficient native code through LLVM.

Most notably, it has a strong emphasis on scientific computing and Julia Arrays type are one of the fastest multi-dimensionnal arrays - or Tensor-like - data structures out there.

## Why use Julia inside Nim ?

* Extending Nim ecosystem with Julia Scientific package
* As an efficient scripting language in a compiled application.

## Tutorial

[Nimjl](https://github.com/Clokk/nimjl) already has some [examples](https://github.com/Clonkk/nimjl/examples/) that explains the basics, make sure to go through them in order.

A more detailed explanations will be written here at a future point in time.
"""

nbSave
