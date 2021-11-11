import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """## Julia Arrays

Julia Arrays are one of the best NDArray data structures available. That's why a special emphasis is made on handling Julia Arrays.

nimjl defines the generic type ``JlArray[T]``. A JlArray is a special JlValue that represent the type ``Array{T}`` in Julia. It's generic so Nim has the information of the underlying type and it's possible to access its buffer and iterate over it.

The closest Nim equivalent would be [Arraymancer](https://github.com/mratsim/Arraymancer) Tensor type.

Just keep in mind, **Julia's Array are column major**, while Nim usually follows C's  convention of Row major.

This is important because you may end up having confusing results if you don't take it into account.

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

When a ``JlArray[T]`` has to be constructed from existing values - i.e. an existing Nim buffer - the easiest way is to either copy the buffer into a ``JlArray[T]`` OR have the array point to the buffer.

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

nbText:"""Note that the slicing syntax is based on Arraymancer slicing syntax, but respect Julia's indexing convention.

## Conversion between JlArray[T] and Arraymancer's Tensor[T] (and dealing with RowMajor/ColMajor)

Working with Arraymancer Tensor isn't that different from working with Array at first glance; the major difference is that Tensor can be either column major or row major so when creating a JlArray by copy from a Tensor, the data will be set to column major order before copying.

"""

nbCode:
  import arraymancer

nbCodeInBlock:
  var localTensor = newTensor[int64](3, 5)
  var i = 0
  localTensor.apply_inline:
    inc(i)
    i
  echo localTensor

  var localArray = localTensor.toJlArray()
  echo localArray

nbText: """Despite localTensor being row major by-default, the JlArray (that is col major by default) still has identical values.

This only applies when a copy is performed :
"""

nbCodeInBlock:
  var localTensor = newTensor[int64](3, 5)
  var i = 0
  localTensor.apply_inline:
    inc(i)
    i
  echo localTensor

  var localArray = jlArrayFromBuffer(localTensor)
  echo localArray

nbText: """When working from the raw buffer of the Tensor, because the order is still column major the ``JlArray[T]`` values are different from the previous examples.

  To convert a ``JlArray[T]`` to a ``Tensor[T]``, simply use ``to`` proc as you would with any other type; with just an additional argument to specify the memory layout of the Tensor created this way:
"""

nbCodeInBlock:
  var localArray = Julia.rand([1, 2, 3, 4, 5], (5, 5)).toJlArray[:int]()
  var localTensor = localArray.to(Tensor[int], colMajor)

  echo localArray
  echo localTensor

  var localTensor2 = localArray.to(Tensor[int], rowMajor)
  assert(localTensor == localTensor2)

nbText:"""Both Tensors have identical indexed values but the buffer are different according to the memory layout argument.

When passing Tensor directly as values in a ``jlCall`` / ``Julia.`` expression, a ``JlArray[T]`` will be constructed by buffer; so you should be aware about the memory layout of the buffer.

"""

nbCode:
  var orderedTensor = newTensor[int]([3, 2])
  var idx = 0
  orderedTensor.apply_inline:
    inc(idx)
    idx
  echo orderedTensor

nbText: """Let's use the simple Tensor above as an example with a trivial funciton such as ``transpose`` and compare the results.

Case 1 : Using Tensor argument directly (no copy):
"""

nbCodeInBlock:
  var res = Julia.transpose(orderedTensor).toJlArray(int)
  echo res
  echo orderedTensor.transpose()

nbText:"""This is expanded to:
"""

nbCodeInBlock:
  # When passing localTensor, a ``JlArray`` is created using ``jlFromBuffer``.
  # Since the Tensor is row major and the Array col major, the order of the values is not conserved
  var res = Julia.transpose(toJlVal(jlArrayFromBuffer(orderedTensor))).toJlArray(int)
  echo res
  echo orderedTensor.transpose()

nbText:"""Therefore, no copy is made : the Julia Array points to the Tensor's buffer.

The indexed values between ``Julia.transpose(...)`` and ``orderedTensor.transpose()`` **are different** because they are indexed differently : Julia Arrays are indexed in column major while this Arraymancer Tensor is in column major.

Case 2 : Copying the Tensor into an Array and using the Array:
"""
nbCodeInBlock:
  var tensorCopied = toJlArray(orderedTensor)
  # Tensor is copier to Array in ColMajor order
  var res = Julia.transpose(tensorCopied).toJlArray(int)
  echo res
  echo orderedTensor.transpose()

nbText:"""On the other hand, on this case because the Array has been created from **a copy**, the indexed value have been copied into ``JlArray`` in column major order.

As a consequence, the indexed value of ``Julia.transpose()`` and ``orderedTensor.transpose()`` **are identical**.

Note that you can use ``swapMemoryOrder`` on an existing ``JlArray[T]`` to obtain a copy of the Array but permuted.
"""

nbCodeInBlock:
  var tensorView = jlArrayFromBuffer(orderedTensor)
  var tensorCopied = toJlArray(orderedTensor)
  echo tensorView
  echo tensorCopied

nbText: """The array are actually different from Julia's point of view: ``tensorView`` is row major values (the Tensor buffer) indexed as column major while ``tensorCopied`` is col major values indexed as col major.

In Nim, the utility proc ``swapMemoryOrder()`` will change and **return a copy** with a swapped memory order (col major -> row major & vice-versa) to handle such cases more easily.

## Broadcasting

One of main appeal of Arrays in Julia, is the ability to broadcast function of a single element.
In Nimjl this is done using the ``jlBroadcast``.
"""

nbCodeInBlock:
  var localArray = @[
    @[4, 4, 4, 4],
    @[4, 4, 4, 4],
    @[4, 4, 4, 4]
  ].toJlArray()
  echo localArray
  var sqrtLocalArray = jlBroadcast(sqrt, localArray).toJlArray(float) # sqrt of int is a float
  echo sqrtLocalArray

nbText: """This is the equivalent in Julia of calling ``sqrt.(localArray)``.

For convenience, the usual broadcasted operators have also been defined:
"""

nbCodeInBlock:
  var localArray = @[
    @[4, 4, 4, 4],
    @[4, 4, 4, 4],
    @[4, 4, 4, 4]
  ].toJlArray()
  echo localArray
  var res = (localArray +. localArray)*.2 -. (localArray/.2)
  echo res

nbText: """## Final word ?
  Thanks for reading this far ! I hope that this tutorial will help you get started mixing Julia and Nim in your application.

  If you found a bug in [nimjl](https://github.com/Clonkk/nimjl), opening an issue will be much appreciated.
  Got a question ? Contact the SciNim team writing these [getting started](https://github.com/scinim/getting-started) either by opening an issue or through the Nim Discord/Matrix on the science channel.

"""

nbSave
