import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """## Julia Arrays

Julia Arrays are one of the best NDArray data structures available. That's why a special emphasis is made on handling Julia Arrays.

nimjl defines the generic type ``JlArray[T]``. A JlArray is a special JlValue that represent the type ``Array{T}`` in Julia. It's generic so Nim has the information of the underlying type and it's possible to access its buffer and iterate over it.

The closest Nim equivalent would be [Arraymancer](https://github.com/mratsim/Arraymancer) Tensor type.

Just keep in mind, **Julia's Array are column major**, while Nim usually follows C's  convention of Row major.

This is important because you may end up having confusing result if you take it into account.

## Creating Arrays

Array creation can be done in multiple different way.

### Native constructor

The most "natural" way of creating a ``JlArray[T]`` is by calling a Julia function that returns an Array.

Important to note, on this case the memory is allocated and owned by Julia, and the JlValue needs to be gc-rooted in order to be used between calls (more on that later):
"""

nbCode:
  import nimjl
  Julia.init()

nbCodeInBlock:
  # Use a Julia constructor to create 5x5 Matrix of Float
  var localArray = Julia.zeros(5, 5)
  # localArray memory is owned by Julia
  echo localArray

nbText:"""### Construct from existing buffer

When a ``JlArray[T]`` has to be constructed from existing values - i.e. an existing Nim buffer - the easiest way is to either copy the buffer into a ``JlArray[T]`` OR have the array points to the buffer.

#### Copying an existing buffer

By copying an existing buffer / Tensor / seq - memory is allocated and owned by Julia during copy; JlValue needs to be gc-rooted in order to be used between calls:
"""

nbCode:
  import std/sequtils

nbCodeInBlock:
  var localNimArray = newSeqWith(5, newSeq[float](5))
  var localArray = toJlArray(localNimArray)
  # localArray memory is owned by Julia
  echo localArray


nbText:"""
pros:
* Julia owning the memory makes it more robust.

cons:
* If you need to go from Nim to Julia to Nim, you have to perform multiple copies

#### Using an existing buffer

* By using an existing buffer (or Tensor) - no memory allocation is performed and Julia does not own the memory. The memory has to be contiguous:
"""
nbCodeInBlock:
  var localNimArray = newSeq[float](25) # Create a Nim buffer of contiguous memory
  var localArray = jlArrayFromBuffer(localNimArray).reshape(5, 5)
  echo localArray
  localNimArray[0] = 14
  # localArray memory is NOT owned by Julia
  # As you can see modifying the buffer modify the Julia Array.
  # Keep in mind when using buffer directly that Julia Array are Column Major.
  echo localArray

nbText:"""As you can see in the previous example, modifying the original sequence modify the ``JlArray[T]``.

pros:
* No copy is performed; you may use a JlArray[T] as a view of the Nim buffer with no-cost.

cons:
* If the Nim buffer is free'd while the ``JlArray[T]`` is still in-use, it will cause a dangling pointer.
* Julia Arrays are column major while Nim usually uses row-major convention. This means you have to be careful when iterating over the Array, to do so continuously (or lose performance).


### Julia GC & rooting values

When using JlArray whose memory is handled by the Julia VM in Nim, you need to gc-root the Arrays in the Julia VM so it doesn't get collected by Julia's gc over successive calls.

This is done by using the ``jlGcRoot`` which calls the C macros ``JL_GC_PUSH`` with the arguments and then calls the C macro ``JL_GC_POP()`` at the end of the template's scope.

For more detailed explanantion regarding ``JL_GC_PUSH()``/ ``JL_GC_POP``, please refer to Julia's official documentation on [embbedding](https://docs.julialang.org/en/v1/manual/embedding/#Memory-Management).
"""

nbCodeInBlock:
  # Use a Julia constructor to create 5x5 Matrix of Float
  var localArray = Julia.zeros(5, 5)
  jlGcRoot(localArray):
    # localArray is gc-rooted as long as you're in ``jlGcRoot`` template scope
    echo localArray
    # Do more stuff... localArray will not be collected by Julia's GC
    echo localArray
    # localArray "rooting" ends here

nbText: """
  Note that if Julia does **not** own the memory, then calling ``jlGcRoot`` on the value is forbidden (and will probably result in a segfault). The Julia VM cannot refer to memory it does not own regarding its gc collection routine.
"""

nbText:"""

### Indexing

``JlArray[T]`` can be indexed in native Nim; through the power of macros, ``[]`` and ``[]=`` operator are mapped to Julia's [getindex](https://docs.julialang.org/en/v1/base/arrays/#Base.getindex-Tuple{Type,%20Vararg{Any,%20N}%20where%20N}) and [setindex!](https://docs.julialang.org/en/v1/base/arrays/#Base.setindex!-Tuple{AbstractArray,%20Any,%20Vararg{Any,%20N}%20where%20N}).

Some examples :
"""

nbCodeInBlock:
    var localArray = @[
      @[1, 2, 3, 4],
      @[5, 6, 7, 8]
    ].toJlArray()

    echo localArray.shape()
    echo localArray
    let
      e11 = localArray[1, 1]
      e12 = localArray[1, 2]
      e21 = localArray[2, 1]
      e22 = localArray[2, 2]

    echo "e11=", e11, " e12=", e12, " e21=", e21, " e22=", e22
    echo typeof(e11)
    echo jltypeof(e11)

nbText: """Several things to notice here:
* calling ``toJlArray()`` perform a copy and re-order the elements into column major order so the ``JlArray[T]`` is of shape [2, 4].
* Index starts at 1; following Julia's indexing rules.
* When indexing "single-element", the result returned is represented as a ``JlArray[T]`` for Nim, but is actually a scalar for Julia.

Let's see a few more examples.

Select a single index on the first axis; select all index on the second axis:
"""

nbCodeInBlock:
  var localArray = @[
    @[1, 2, 3, 4],
    @[5, 6, 7, 8]
  ].toJlArray()

  let e10 = localArray[1, _]
  echo e10
  echo e10.shape
  echo typeof(e10)
  echo jltypeof(e10)

nbText: """Select a single index on the first axis; select the indexes >=2 and <= 4 on the second axis:
"""

nbCodeInBlock:
  var localArray = @[
    @[1, 2, 3, 4],
    @[5, 6, 7, 8]
  ].toJlArray()

  let e1 = localArray[2, 2..4]
  echo e1
  echo e1.shape
  echo typeof(e1)
  echo jltypeof(e1)


nbText: """To exclude the last value, the syntax is simply ..<:
"""

nbCodeInBlock:
  var localArray = @[
    @[1, 2, 3, 4],
    @[5, 6, 7, 8]
  ].toJlArray()

  let e1inf = localArray[2, 2..<4]
  echo e1inf
  echo e1inf.shape
  echo typeof(e1inf)
  echo jltypeof(e1inf)

nbText:"""
Select a single index on the first axis; Select all index between the second element and the second-to-last element from  on the second axis:
"""

nbCodeInBlock:
  var localArray = @[
    @[1, 2, 3, 4],
    @[5, 6, 7, 8]
  ].toJlArray()

  let e1hat2 = localArray[2, 2..^2]
  echo e1hat2
  echo e1hat2.shape
  echo typeof(e1hat2)
  echo jltypeof(e1hat2)

nbText:"""Note that the slicing syntax is based on Arraymancer slciing syntax, but respect Julia's indexing convention.

## Conversion between JlArray[T] <-> Tensor[T]
TODO

"""

nbSave
