import nimib, nimibook

nbInit()
nbUseNimibook

nbText: """
# Using Python with Nim

In this tutorial, we explore how to use [Nimpy](https://github.com/yglukhov/nimpy) to integrate Python code with Nim.

There are 2 potential motivations for using Python:
* Extending the Nim Scientific computing ecosystem; mostly with Scipy / Numpy.
* Having a scripting language inside a compiled application


## Using Python as a scripting language in Nim
"""

nbCode:
  import std/os # Will be used later
  import nimpy
  let py = pyBuiltinsModule()
  discard py.print("Hello world from Python..")

nbText: """
  That's basically all there is to it.
  If you don't want to use to dot operator (which can get confusing), it is also possible use ``callMethod`` directly
"""

nbCode:
  discard callMethod(py, "print", "This is effectively identical to the previous call")

nbText: """
  Most type conversion Nim -> Python will be done automatically though Nimpy templates. Python -> Nim type conversion has to be called manually with the ``to()`` API.

  Let's see how it works in practice. In order to do that, we are going to create a local Python file with our custom functions, import it in Nim and call the Python function from Nim and convert the result back to nim types.

  The next portion will create said Python file using Nim code. If you're looking to reproduce this tutorial  at home, you can (and probably should) do it using your favorite text editor.
"""

nbCodeInBlock:
  # Create a new file
  let mymod = open(getCurrentDir() / "mymod.py", fmWrite)
  mymod.write("""def myfunc(inputArg):
  outputArg = {}
  outputArg["argFloat"] = inputArg["argFloat"] / 2
  outputArg["argStr"] = inputArg["argStr"][::-1]
  sortedList = sorted(inputArg["argSeq"])
  outputArg["argSeq"] = sortedList
  return outputArg
""")
  mymod.close()


nbText: """
  Now, onto the good parts :
"""

nbCode:
  type
    MyObj* = object
      argFloat: float
      argStr: string
      argSeq: seq[int]

  let
    nimSeq: seq[int] = @[6, 3, 4, 2, 7, 1, 8, 5]
    nimTup = MyObj(argFloat: 36.66, argStr: "I'm a string", argSeq: nimSeq)

  # Let's import our Python file
  # First, add the location of the Pythong to sys.path, as you would do in Python
  let sys = pyImport("sys")
  discard sys.path.append(getCurrentDir())
  # Second, import your file
  let mymod = pyImport("mymod")

  let retValue = mymod.myfunc(nimTup)
  echo typeof(retValue)
  # We can still use retValue as an argument for Python function
  discard py.print(retValue)

nbText: """
  As you can see, by default every Python function called will return a PyObject. To convert this PyObject into a useful Nim type simply do :
"""

nbCode:
  let nimValue = retValue.to(MyObj)
  echo typeof(nimValue)
  echo nimValue

nbText: """
  Note that this example works with an object, but most Nim data structure are convertible to PyObject through Nimpy, including (but not limited to) : Table, JsonNode, Set, OpenArray, Enum, Tuple etc..

## Extending Nim through Scipy & Numpy

  Now that we know how to use Python through Nim, let's see how we can use Nimpy / Scipy scientific function through Nim.

  The main difficulty is to work with numpy ndarray type in Nim.

  In order to do that, we'll use the [scinim/numpyarrays API](https://github.com/SciNim/scinim/blob/main/scinim/numpyarrays.nim).
  By default, the conversion is done from/to Arraymancer Tensor; but the API covers ``ptr UncheckedArray[T]`` so it can be extended to any type with an underlying data buffer.

"""

nbCode:
  import arraymancer
  import scinim/numpyarrays

  let np = pyImport("numpy")
  # Create a Tensor
  var mytensor = @[
    @[1.0, 2.0, 3.0],
    @[4.0, 5.0, 6.0],
    @[7.0, 8.0, 9.0],
  ].toTensor

  # As you can see, Tensor are converted automatically to np.ndarray
  discard py.print(mytensor)
  var myarray = toNdArray(mytensor)
  echo myarray.dtype()
  echo myarray.shape

nbText: """
  Now let's do a simple 1d interplation using Scipy
"""

nbCode:
  let interp = pyImport("scipy.interpolate")
  var
    mypoints = @[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, ].toTensor
    myvalues = @[10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, ].toTensor
    x_coord = toNdArray(mypoints)
    y_coord = toNdArray(myvalues)

  var f_interp = interp.interp1d(x_coord, y_coord, "cubic")
  discard py.print(f_interp)
nbText: """
  The result of interp1d is an interpolator function. In Nim, it's necessary to call it explicitly using ``callObject`` proc.
"""

nbCode:
  # The result of interp2d is a function object that can be called through __call__
  var val_at_new_point = callObject(f_interp, 1.5).to(float)
  # Yay, we just did a BiCubic interpolation !
  echo val_at_new_point

  var new_points_coord = @[2.5, 3.5, 4.5, 5.5].toTensor().toNdArray()
  var new_values = callObject(f_interp, new_points_coord).toTensor[:float]()
  echo new_values


nbText: """
  And that's it !
"""

nbCodeInBlock:
  removeFile(getCurrentDir() / "mymod.py")


nbSave
