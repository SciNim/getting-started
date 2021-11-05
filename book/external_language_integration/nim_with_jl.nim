import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# 1) Using Julia with Nim

In this tutorial, we explore how to use [Nimjl](https://github.com/Clokk/nimjl) to integrate [Julia](https://julialang.org/) code with Nim.

## 1.1) What is Julia ?

Julia is a dynamicalyl typed scripting language designed for high performance; it compiles to efficient native code through LLVM.

Most notably, it has a strong emphasis on scientific computing and Julia Arrays type are one of the fastest multi-dimensionnal arrays - or Tensor-like - data structures out there.

## 1.2) Why use Julia inside Nim ?

* Extending Nim ecosystem with Julia Scientific package
* As an efficient scripting language in a compiled application.

# 2) Tutorial

[Nimjl](https://github.com/Clokk/nimjl) already has some [examples](https://github.com/Clonkk/nimjl/examples/) that explains the basics, make sure to go through them in order.

## 2.1) Basic stuff


"""
nbCode:
  import nimjl
  Julia.init() # Must be done once in the lifetime of your program

  discard Julia.println("Hello world !") # Invoke the println function from Julia. This function return a nil JlValue

  # Julia.exit() # -> This call is optionnal since it's called at the end of the process but making the exit explicit makes code more readable.
  # All successive Julia calls after the exit will probably segfault

nbText: """The ``Julia.init()`` calls initialize the Julia VM. No call before the init will work.

Note that internally, this is rewritten to :
"""

nbCode:
  # Julia.init()
  discard jlCall("println", "Hello world !")

nbText: """As you can see, both code are identical.

But wait didn't we just pass Nim string to Julia ? How does that work ?

## 2.2) Julia's typing system

As mentionned, Julia is **dynamically typed**, which means that from Nim point of view, every Julia object is a pointers of the C struct ``jl_value_t`` - mapped in Nim to ``JlValue``.

For convenience:
* ``proc jltypeof(x: JlVal) : string`` will invoke the Julia function ``typeof`` and convert the result to a string.
* ``proc `$`(x: JlVal) : string`` will call the Julia function ``string`` and convert the result to a string - this allow us to call ``echo`` with JlValue and obtain the same output as Julia's ``println``.

### 2.2.1) Converting Nim type to Julia value

Most Nim value can be converted to JlValue through the function ``toJlVal`` or its alias ``toJlValue`` (I always got the two name confused so I ended up defining both...).

When passing a Nim value as a Julia argument through ``jlCall`` or ``Julia.myfunction``, Nim will automatically convert the argument by calling ``toJlVal``.

Let's see in practice what it means:
"""

nbCode:
  var res = Julia.sqrt(255.0)
  echo typeof(res)
  echo jltypeof(res)
  echo res


nbText: """
**This operation will perform a copy** (almost always).

### 2.2.2) Converting from Julia to Nim

In the previous example we calculated the square root of 255.0, stored in a JlValue. But using JlValue in Nim is hardly practical, so let's how to convert it back to a float:

"""

nbCode:
  var nimRes = res.to(float64)
  echo nimRes
  echo typeof(nimRes)
  import std/math
  # Check the result
  assert nimRes == sqrt(255.0)

nbText: """### 2.2.3) Using non-POD data structures

#### Dict() <-> Table

Julia Dict() type will be mapped to ``Table`` in Nim and vice-versa. A copy is performed.

"""

nbCode:
  var nimTable: Table[int64, float64] = {1'i64: 0.90'f64, 2'i64: 0.80'f64, 3'i64: 0.70'f64}.toTable
  block:
    var r = Julia.`pop!`(nimTable, 1)
    echo r
    echo nimTable # The initial object has not been modified because a copy is performed when passing Nim type to Julia. call

nbText: """As you can see, the Nim object here has not been modified despite a value being pop'ed.

So if you want to handle the value, it is best to first convert the Table then modify it.

"""

nbCode:
  var jlDict = toJlVal(nimTable)
  block:
    var r = Julia.`pop!`(jlDict, 1)
    echo r
    echo jlDict

nbText: """The key ``1`` has effectivelent been removed.

Note, that you can also use ``[]`` and ``[]=`` operator on Dict().
"""

nbCode:
  block:
    var r = jlDict[2]
    echo r
    jlDict[2] = -1.0
    echo jlDict

nbText:"""#### Tuples

Julia named tuples will be mapped to Nim named tuple. Note that since Nim tuples type are CT defined while Julia tuples can be made at run-time, using Tuple is not always trivial.
The key is to know beforehand the fields of the Tuple in order to easily use it from Nim. A copy is always performed.

#### Object

For object, the conversion proc is done by iterating over the object's fields and calling the conversion proc.

In order for the conversion to be possible, it is necessary that the type is declared in both Nim and Julia (as a mutable struct) and that the empty constructor is defined in Julia.
"""

nbText: """
### Manipulating Arrays


### Calling external module

"""


nbSave
