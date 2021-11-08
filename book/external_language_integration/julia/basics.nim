import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# Using Julia with Nim

In this tutorial, we explore how to use [Nimjl](https://github.com/Clokk/nimjl) to integrate [Julia](https://julialang.org/) code with Nim.

## What is Julia ?

Julia is a dynamicalyl typed scripting language designed for high performance; it compiles to efficient native code through LLVM.

Most notably, it has a strong emphasis on scientific computing and Julia Arrays type are one of the fastest multi-dimensionnal arrays - or Tensor-like - data structures out there.

## Why use Julia inside Nim ?

* Extending Nim ecosystem with Julia Scientific package
* As an efficient scripting language in a compiled application.

# Tutorial

[Nimjl](https://github.com/Clokk/nimjl) already has some [examples](https://github.com/Clonkk/nimjl/examples/) that explains the basics, make sure to go through them in order.

## Basic stuff

Nimjl is a mostly Nim wrapper around the C API of Julia; and then some syntax suagr around it to make it more easily to use. That means that inherently, Nimjl is limited to the capabilities of the C-API of Julia.

Now let's what the code looks like :
"""
nbCode:
  import nimjl
  Julia.init() # Must be done once in the lifetime of your program

  discard Julia.println("Hello world !") # Invoke the println function from Julia. This function return a nil JlValue

  Julia.exit() # -> This call is optionnal since it's called at the end of the process but making the exit explicit makes code more readable.
  # All successive Julia calls after the exit will probably segfault

nbText: """The ``Julia.init()`` calls initialize the Julia VM. No call before the init will work.

The ``Julia.exit()`` calls is optionnal since it's added as an exit procs (see [std/exitprocs](https://nim-lang.org/docs/exitprocs.html) )

Internally, this is rewritten to :
"""

nbCode:
  discard jlCall("println", "Hello world !")

nbText: """Both code are identical; like mentionned the ``Julia.`` is syntaxic sugar for calling Julia function; it always returns a JlValue (that can be nil if the Julia function does not return anything).

The equivalent C code would be :
```c
    jl_function_t *func = jl_get_function(jl_base_module, "println");
    jl_value_t *argument = jl_eval_string("Hello world !");
    jl_call1(func, argument);
```

"""

nbText:"""As mentionned, Julia is **dynamically typed**, which means that from Nim point of view, every Julia object is a pointers of the C struct ``jl_value_t`` - mapped in Nim to ``JlValue``.

### Converting Nim type to Julia value

Most Nim value can be converted to JlValue through the function ``toJlVal`` or its alias ``toJlValue`` (I always got the two name confused so I ended up defining both...).

When passing a Nim value as a Julia argument through ``jlCall`` or ``Julia.myfunction``, Nim will automatically convert the argument by calling ``toJlVal``.

Let's see in practice what it means:
"""

nbCode:
  import nimjl
  Julia.init()
  var res = Julia.sqrt(255.0)
  echo res

  echo typeof(res)
  echo jltypeof(res)

nbText: """
**This operation will perform a copy** (almost always).

For reference, the equivalent C code would be :
```c
jl_function_t *func = jl_get_function(jl_base_module, "sqrt");
jl_value_t *argument = jl_box_float64(255.0);
jl_value_t *ret = jl_call1(func, argument);
double cret = jl_unbox_float64(ret);
printf("cret=%f \n", cret);
```

### Converting from Julia to Nim

In the previous example we calculated the square root of 255.0, stored in a JlValue. But using JlValue in Nim is hardly practical, so let's how to convert it back to a float:

"""

nbCode:
  var nimRes = res.to(float64)
  echo nimRes
  echo typeof(nimRes)
  import std/math
  # Check the result
  assert nimRes == sqrt(255.0)


nbText:"""
For convenience:
* ``proc jltypeof(x: JlVal) : string`` will invoke the Julia function ``typeof`` and convert the result to a string.
* ``proc `$`(x: JlVal) : string`` will call the Julia function ``string`` and convert the result to a string - this allow us to call ``echo`` with JlValue and obtain the same output as Julia's ``println``.

Keep these procs in mind as they will often be used in the following examples.
"""

nbSave
