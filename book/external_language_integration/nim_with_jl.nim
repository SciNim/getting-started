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

If the type is not known to Julia, the Nim object will be mapped to a NamedTuple (losing the mutability).

Let's how it works in practice. First we will have to create a local module and include it.

"""
nbCode:
  import std/os # Will be used later
nbCodeInBlock:
  # Create a new file
  let mymod = open(getCurrentDir() / "mymod.jl", fmWrite)
  mymod.write("""
module localexample
  mutable struct Foo
    x::Int
    y::Float64
    z::String
    # Nim initialize the Julia variable with empty constructor by default
    Foo() = new()
    Foo(x, y, z) = new(x, y, z)
  end
  function applyToFoo(foo::Foo)
    foo.x += 1
    foo.y *= 2/3
    foo.z *= " General Kenobi !"
  end
  export Foo
  export applyToFoo
end
""")
  mymod.close()

nbText: """Now that we have our local Julia module, let's include it and convert object to Nim.
"""

nbCode:
  # Create the same Foo typr
  type
    Foo = object
      x: int
      y: float
      z: string

  # Include the file
  jlInclude(getCurrentDir() / "mymod.jl")
  # This is equivalent to Julia `using ...`
  jlUseModule(".localexample")

nbText: """Now let's see how conversion works for object:

"""

nbCode:
    var foo = Foo(x: 144, y: 12.0, z: "123")
    var jlfoo = toJlVal(foo)
    echo jlfoo
    echo typeof(jlfoo) # From Nim's point of view it's still a JlValue
    echo jltypeof(jlfoo) # From Julia's point of view, it's a Foo object.

nbText: """The object gets converted to the mutable struct type "Foo" in Julia.

Despite being a JlValue for Nim, you can still access and modify its field using `.` - just as you would a Nim object.

Internally, this will call Julia's metaprogramming function getproperty / setproperty!.

Let's see :
"""

nbCode:
  echo jlfoo.x
  echo typeof(jlfoo.x)
  echo jltypeof(jlfoo.x)

  jlfoo.x = 20
  jlfoo.y = -11.0
  jlfoo.z = "Hello there !"
  echo jlfoo

nbText: """


And like all JlValue, it can be used as a function argument. For example, let's call the function ``applyToFoo`` we previously defined in Julia.

This function adds 1 to the x field; multiply the y field by 2/3; append the string "General Kenobi !" to the z field.
"""

nbCode:
  discard Julia.applyToFoo(jlfoo)
  echo jlfoo

nbText: """And there we have it. ``jlfoo`` has been modified.

Finally, let's convert back the Julia object to a Nim "Foo" object :

"""

nbCode:
  var foo2 = jlfoo.to(Foo)
  echo foo2
  echo typeof(foo2)

nbText: """foo2 is now back in Nim land with the previously modified value.

Of course, this dummy examples doesn't do much but it demonstrate the type of workflow you can setup between Nim and Julia.

### Manipulating Arrays

Julia Arrays are one of the best NDArray data structures available. That's why a special emphasis is made on handling Julia Arrays.

nimjl defines the generic type ``JlArray[T]``. A JlArray is a special JlValue that represent the type ``Array{T}`` in Julia. It's generic so Nim has the information of the underlying type and it's possible to access its buffer and iterate over it.

The closest Nim equivalent would be [Arraymancer](https://github.com/mratsim/Arraymancer) Tensor type.

Just keep in mind, **Julia's Array are column major**, while Nim usually follows C's  convention of Row major.

This is important because you may end up having confusing result if you take it into account.

#### Creating Arrays

TODO

Who owns the memory ?
Memory allocation

* From a buffer
* From a 1D seq / openarray
* From a seq[seq]
* From a Tensor
* From Julia itself

"""

nbCode: # TODO
  discard

nbText: """
#### Conversion between JlArray[T] <-> Tensor[T]
TODO

#### Indexing (and its side effects)
TODO

#### Basic algorithm
TODO

Installing a package, calling an algorithm, getting the result as an Arraymancer

"""

nbCodeInBlock:
  removeFile(getCurrentDir() / "mymod.jl")

nbSave
