import nimib, nimibook
import std/os

nbInit(theme = useNimibook)

nbText: """Previously, we've seen how the basics of Nimjl works; now let's explore how to work with non-trivial types when calling functions.

## Julia Dict() and Nim Table[U, V]

Julia Dict() type will be mapped to ``Table`` in Nim and vice-versa. A copy is performed.

"""

nbCode:
  import nimjl
  Julia.init()

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

nbText: """The key ``1`` has effectively been removed.

Note, that you can also use ``[]`` and ``[]=`` operator on Dict().
"""

nbCode:
  block:
    var r = jlDict[2]
    echo r
    jlDict[2] = -1.0
    echo jlDict

nbText:"""## Tuples

Julia named tuples will be mapped to Nim named tuple. Note that since Nim tuples type are CT defined while Julia tuples can be made at run-time, using Tuple is not always trivial.
The key is to know beforehand the fields of the Tuple in order to easily use it from Nim. A copy is always performed.

## Object

For object, the conversion proc is done by iterating over the object's fields and calling the conversion proc.

In order for the conversion to be possible, it is necessary that the type is declared in both Nim and Julia (as a mutable struct) and that the empty constructor is defined in Julia.

If the type is not known to Julia, the Nim object will be mapped to a NamedTuple (losing the mutability).

Let's how it works in practice. First we will have to create a local module and include it.

"""

nbFile("mymod.jl"):"""
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
"""

nbText: """Now that we have our local Julia module, let's include it and convert object to Nim.
"""

nbCode:
  # Create the same Foo type as the one defined in Julia
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

This function adds 1 to the x field; multiply the y field by 2/3; append the string " General Kenobi !" to the z field.
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

Next, let's talk about arrays
"""

removeFile(getCurrentDir() / "mymod.jl")

nbSave
