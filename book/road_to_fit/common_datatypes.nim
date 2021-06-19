import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# Basic data types encountered in scientific computing in Nim

Most operations using scientific computing packages in Nim will require one of three
different data types:
- `seq[T]`
- `Tensor[T]`
- `DataFrame`

to store multiple scalar values (typically `float` values).

`T` is the typical letter used to indicate generics in Nim. This means the explicit type
will be determined by the argument / desired type to store in the container, for example
`seq[int], Tensor[float]` etc.

There are of course further types used in many packages, but these three are typically
used to actually store data. Other objects may wrap any of these for different purposes,
e.g. [numericalnim](https://github.com/hugogranstrom/numericalnim) contains different
helper objects for integration or interpolation.

We will now look at each of these three data types individually and discuss how to create
variables of each type and what typical use cases are.

## `seq[T]` - homogeneous, dynamically resizable sequence

`seq[T]` is the default, dynamically resizable container from Nim's standard library. As the
single generic argument `T` implies it is homogeneous, which means one sequence stores
elements of a single data type.

Their implementation is essentially a pointer to a memory array, the length of the allocated
memory as well as the length of elements actually stored in it. We will discuss this further
down in section "Length and capacity of a sequence".

In addition to `seq[T]` Nim also supports fixed size arrays. While these can be very useful
they won't be discussed here.

The standard library provides different ways to construct a sequence. Let's look at the
default two constructors first:
"""

nbCode:
  let x1 = @[0.0, 1.0, 2.0, 3.0]
  echo x1
  echo "Length: ", len(x1)
nbText: """
The first constructor explicitly converts a number of elements into a sequence with
4 elements. The length of the sequence can be accessed using `len`.
"""
nbCode:
  var y1 = newSeq[float]()
  echo "Length: ", y1.len
nbText: """
The second way to construct a sequence uses the `newSeq` procedure. It receives the
generic type that should be housed in the sequence and as an argument the number of
initial elements (the default being 0).
"""
nbCode:
  var y2 = newSeq[float](4)
  echo y2
  echo "Length: ", y2.len
nbText: """
`y2` then uses the `newSeq` constructor to directly construct a sequence of floats of
length 4. All elements in the sequence are initialized to zero!

From here we can modify any created sequence, remove elements or add new elements as
long as the variable is declared as a `var` (instead of `let`).

### Access

Elements in the sequence are accessed using bracket `[]` access:
"""
nbCode:
  echo x1[2]

nbText: """
### Mutation

Basic mutation of elements in the sequence is done using `[]=` (in Nim terms), which is simply
bracket access and an assignment:
"""
nbCode:
  y2[0] = 5.0
  echo y2
nbText: """

New elements are added using `add` as is typical in Nim:
"""
nbCode:
  y1.add 10.0
  echo y1
  echo "Length: ", y1.len
nbText: """
So `y1` now contains 1 element instead of 0.

Deleting elements is also supported, via `delete` or `del`. Both procedures take the index
to be removed. `delete` keeps the order of the sequence intact, whereas `del` simply overwrites
the given index with the last element of the sequence and reduces the length by one. Compare:
"""
nbCode:
  var x2 = x1
  var x3 = x1
  echo "Starting from: ", x1
  x2.delete(1)
  echo "Remove index 1 using `delete`: ", x2
  x3.del(1)
  echo "Remove index 1 using `del`: ", x3
nbText: """
See how the order of `x3` is now different, whereas `x2` has the same order just with
index 1 removed.

### Length and capacity of a sequence

Consider the following code:
"""
nbCode:
  var z = newSeq[int]()
  for i in 0 ..< 10:
    z.add i
nbText: """
A naive implementation of a sequence would have to reallocate the memory underlying the sequence for
each call to `add`. To avoid the overhead of all these copying operations, the implementation
overallocates by a certain amount. This means reallocation is only required if the actual underlying
capacity is exceeded.

This has practical use cases as well. Sometimes we may not know *exactly* how many elements we will
store in a sequence, but we have a good idea of the order. In those cases we cannot very well create
a sequence with an existing length using `newSeq` (if we overestimate we suddenly have a number of
empty entries).

For that usecase we can use `newSeqOfCap`. It creates a sequence of length 0 but whose capacity is the
given number:
"""
nbCode:
  var st = newSeqOfCap[int](100)
  echo "Length: ", st.len
nbText: """
As we can see the sequence is currently empty. But if we add to it, the sequence won't have to
reallocate several times. In this way we can often get away with at most one reallocation or
zero, if we accept a bit of overallocation.
"""
nbCode:
  for i in 0 ..< 100:
    st.add i
nbText: """
So this operation won't reallocate.

Note: for even more performance critical code there is also `newSeqUninitialized`, which creates a
sequence of N elements that are *not* zero initialized to save one more (possibly useless) loop
over the memory.

### Filling a seq with a fixed value

Sometimes we wish to create a sequence that is initialized not to zero, but some other constant
value. For this we can use `newSeqWith` from `sequtils`:
"""
nbCode:
  import sequtils
  echo newSeqWith(3, 5.5)
nbText: """
which takes as the first argument the size of the resulting sequence and as the second argument the
value to initialize all values to.

Note: this can also be used to create nested sequences:
"""
nbCode:
  echo newSeqWith(3, newSeqWith(3, 5))
nbText: """
which gives us a nested sequence of `seq[seq[int]]` where each element is a sequence of
integers with value 5.

### A few more typical ways to create sequences

To finish of this section, let's look at a few more sequence constructors that are often useful.

Nim supports slices using the syntax `a .. b`, which includes all values from `a` to including `b`.
Together with `toSeq` it can be used to generate a sequence:
"""
nbCode:
  echo toSeq(10 .. 14)
nbText: """
This essentially takes the role of `arange` from numpy. Of course this only generates sequences of integers.

For succinctness (but not performance) we can convert such a sequence using `mapIt` to map
each element from an input type to some other type:
"""
nbCode:
  echo toSeq(10 .. 14).mapIt(it.float)
nbText: """
Returns a sequence of floats instead.

Similarly, it is often desirable to get a linearly spaced sequence of numbers. `numericalnim` also
provides a `linspace` implementation. Let's create 5 evenly spaced points between 1 and 2:
"""
nbCode:
  import numericalnim
  echo linspace(1.0, 2.0, 5)
nbText: """
Finally, one may need a sequence of randomly sampled numbers. The `random` module of the Nim
standard library provides a `rand` procedure we can combine with `mapIt`:
"""
nbCode:
  import random
  randomize()
  echo toSeq(0 ..< 5).mapIt(rand(10.0))
nbText: """
samples 5 floating point numbers between 0 and 10.

## `Tensor[T]` - an ND-array type from [Arraymancer](https://github.com/mratsim/Arraymancer)

Arraymancer provides an ND-array type called `Tensor[T]` that is best compared to a numpy
ndarray. Same as a sequence `seq[T]` it can only contain a single type. In contrast to it
however, it cannot be resized easily (only *reshaped*).

Under the hood the data is stored as a pointer + length pair for types that can be copied
using `copyMem` (Nim's `memcpy`). Otherwise it contains a `seq[T]` for the data. The major
difference between a sequence and a tensor is the ability to handle multidimensional data
efficiently.

In case of a `seq[T]` we either have to manually handle the indexing of the sequence or
deal with the inefficiencies of a nested sequence `seq[seq[T]]`. An Arraymancer tensor
always stores data in a one-dimensional data storage. Not only does it make iterating over
all data faster, it also allows for essentially free reshaping of the data, because the
shape is only a piece of meta data.

Another important bit of information is that tensors have reference semantics. That means
assigning a tensor to a new variable and modifying that variable also modifies the initial
tensor! This is for efficiency reasons to not copy all the data for each assignment.

Two most basic ways to create are shown below:
"""
nbCode:
  import arraymancer
  let t1 = @[1.0, 2.0, 3.0].toTensor
nbText: """
First we can just create a tensor from a (possibly nested) sequence or array using `toTensor`.

Secondly:
"""
nbCode:
  let t2 = newTensor[float](9)
nbText: """
This is the default tensor constructor. It creates a tensor of type `Tensor[float]` with
10 elements that is zero initialized. If multiple elements are given to the procedure a tensor
of different shape is created.
"""
nbCode:
  let t3 = newTensor[float](3, 3)
nbText: """
creates a tensor 2 dimensional tensor of size 3 in both dimensions (essentiall a 3x3 matrix).

Note that due to the shape being a piece of meta data, it is cheap to convert from one shape
to another using `reshape`.
"""
nbCode:
  let t4 = newTensor[float](9).reshape(3, 3)
nbText: """
This essentially does not have any meaningful overhead over the creation of `t3` above.

Some more ways to construct a tensor:
"""
nbCode:
  let t5  = zeros[float](9) # a tensor that is explicit 0, the default
  let t6  = ones[float](9) # a tensor that is initialized to 1
  let t7  = newTensorWith[float]([3, 3], 5) # a 3x3 tensor initialized to 5
  let t8  = newTensorUninit[float](10) # a tensor that is *not* initialized
  let t9  = arange(0, 10) # the range 0 to 10 as a tensor
  let t10 = linspace(0.0, 10.0, 1000) # 1000 linearly spaced points between 0 and 10
nbText: """
These are only a few common ways to create a tensor.

### Access and mutation

Arraymancer tensors are very similar to the Nim standard library `seq[T]` in terms of
their element access and element mutation, with the aforementioned difference of reference
semantics.

However, because tensors deal with possibly multidimensional data, there are ways to
slice and select parts of a tensor using syntax comparable to numpy's fancy indexing.
Furthermore, support for element-wise operations between multiple tensors are supported.

As we won't make use of that in this tutorial, we won't cover it here. See the Arraymancer
[tutorial section](https://mratsim.github.io/Arraymancer/tuto.slicing.html) to get an idea.

### More

Of course Arraymancer provides a large amount of additional functionality, starting from
linear algebra, to statistics, machine learning and more. View the full documentation here:

https://mratsim.github.io/Arraymancer/
"""
nbSave
