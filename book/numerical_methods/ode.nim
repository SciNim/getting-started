import nimib except Value
import nimibook
import std / [strformat, strutils]


nbInit(theme = useNimibook)
nb.useLatex

let fixedODESubset = @["heun2", "rk4"]
let adaptiveODESubset = @["rk21", "tsit54"]

nbText: hlMd"""
# Solve ordinary differential equations in Nim

Ordinary differential equations (ODEs) describe so many aspects of nature, but many of them do not have
simple solutions you can solve using pen and paper. That is where numerical solutions come in. They allow
us to solve these equations approximately. We will use [numericalnim](https://github.com/SciNim/numericalnim)
for this. The required imports are:
"""

nbCode:
  import ggplotnim, numericalnim, benchy, std / [math, sequtils]

nbText: hlMd"""
We will use an ODE with a known solution to be able to compare our numerical solution with
the analytical one. The ODE we will solve is:
$$y' = y (1 - y)$$
$$y(0) = 0.1$$
which has the solution of a sigmoid:
$$y(t) = \frac{1}{1 + 9 e^{-t}}$$

This equation can for example describe a system which grows exponentially at the beginning, but due to
limited amounts of resources the growth stops and it reaches an equilibrium. The solution looks like this:
"""

block:
  let t = linspace(0.0, 10.0, 100)
  let y = t.mapIt(1 / (1 + 9*exp(-it)))
  let df = toDf(t, y)
  ggplot(df, aes("t", "y")) +
    geom_line() +
    ggtitle("ODE solution") +
    ggsave("images/sigmoid_solution.png")

nbImage("images/sigmoid_solution.png")

nbText: hlMd"""
## Let's code
Let us create the function for evaluating the derivative $y'(t, y)$:
"""

nbCode:
  proc exact(t: float): float =
    1 / (1 + 9*exp(-t))
 
  proc dy(t: float, y: float, ctx: NumContext[float, float]): float =
    y * (1 - y)

nbText: hlMd"""
`numericalnim` expects a function of the form `proc(t: float, y: T, ctx: NumContext[T, float]): T`,
where `T` is the type of the function value (can be `Tensor[float]` if you have a vector-valued function),
and `ctx` is a context variable that allows you to pass parameters or save information between function calls.
Now we need to define a few parameters before we can do the actual solving:
"""

nbCode:
  let t0 = 0.0
  let tEnd = 10.0
  let y0 = 0.1 # initial condition
  let tspan = linspace(t0, tEnd, 20)
  let odeOptions = newODEoptions(tStart = t0)

nbText: hlMd"""
Here we define the starting time (`t0`), the value of the function at that time (`y0`), the time points we want to get
the solution at (`tspan`) and the options we want the solver to use (`odeOptions`). There are more options you can pass,
for example the timestep `dt` used for fixed step-size methods and `dtMax` and `dtMin` used by adaptive methods.
The only thing left is to choose which method we want to use. The fixed step-size methods are:
"""

let references = {
  "heun2": "https://en.wikipedia.org/wiki/Heun%27s_method",
  "ralston2": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Ralston's_method",
  "kutta3": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Kutta's_third-order_method",
  "heun3": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Heun's_third-order_method",
  "ralston3": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Ralston's_third-order_method",
  "ssprk3": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Third-order_Strong_Stability_Preserving_Runge-Kutta_(SSPRK3)",
  "ralston4": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Ralston's_fourth-order_method",
  "kutta4": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#3/8-rule_fourth-order_method",
  "rk4": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Classic_fourth-order_method",
  "rk21": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Heun%E2%80%93Euler",
  "bs32": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Bogacki%E2%80%93Shampine",
  "dopri54": "https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods#Dormand%E2%80%93Prince",
  "tsit54": "http://users.uoa.gr/~tsitourasc/RK54_new_v2.pdf",
  "vern65": "https://www.sfu.ca/~jverner/"
}.toTable

proc referenceList(list: openArray[string]): string =
  result = ""
  for m in list:
    result &= "- "
    result &= (
      if m in references:
        &"[{m}]({references[m]})"
      else:
        m
    )
    result &= '\n'


nbText(referenceList(fixedODE))

nbText: "And the adaptive methods are:"

nbText(referenceList(adaptiveODE))

nbText: hlMd"""
That is a lot to choose from, but its hard to go wrong with any of the adaptive methods `dopri54, tsit54 & vern65`. So let's use `tsit54`!
"""

nbCode:
  let (t, y) = solveOde(dy, y0, tspan, odeOptions, integrator="tsit54")
  let error = abs(y[^1] - exact(t[^1]))
  echo "Error: ", error

nbText: hlMd"""
We call `solveOde` with our parameters and it returns one `seq` with our time points and one with our solution at those points.
We can check the error at the last point and we see that it is around `3e-16`. Let's plot this solution:
"""

nbCodeInBlock:
  let yExact = t.mapIt(exact(it))
  var df = toDf(t, y, yExact)
  df = df.gather(["y", "yExact"], key="Class", value="y")
  ggplot(df, aes("t", "y", color="Class")) +
    geom_line() +
    ggtitle("Tsit54 Solution") +
    ggsave("images/tsit54_solution.png")

nbImage("images/tsit54_solution.png")

nbText: hlMd"""
As we can see, the graphs are very similar so it seems to work :D.

Now you might be curios how well a few of the other methods performed, and here you have it:
"""

for m in concat(fixedODESubset, adaptiveODESubset):
  let (t, y) = solveOde(dy, y0, tspan, odeOptions, integrator=m)
  let error = abs(y[^1] - exact(t[^1]))
  nbText: &"- {m}: {error:e}"

nbText: hlMd"""
We can see that the higher-order methods has a lower error compared to the lower-order ones. Tweaking the
`odeOptions` would probably get them on-par with the others. There is one parameter we haven't talked about though,
the execution time. Let's look at that and see if it bring any further insights:
"""

nbCodeInBlock:
  for m in concat(fixedODESubset, adaptiveODESubset):
    benchy.timeIt m:
      keep solveOde(dy, y0, tspan, odeOptions, integrator=m)

nb.blk.code = ""

nbText: hlMd"""
As we can see, the adaptive methods are orders of magnitude faster while achieving roughly the same errors.
This is because they take fewer and longer steps when the function is flatter and only decrease the
step-size when the function is changing more rapidly.

## Vector-valued functions
Now let us look at another example which is a simplified version of what you might get from discretizing a PDE, multiple function values.
The equation in question is
$$y'' = -y$$
$$y(0) = 0$$
$$y'(0) = 1$$
This has the simple solution
$$y(t) = \sin(t)$$
but it is not on the form `y' = ...` that `numericalnim` wants, so we have to rewrite it.
We introduce a new variable $z = y'$ and then we can rewrite the equation like:
$$y'' = (y')' = z' = -y$$
This gives us a system of ODEs:
$$y' = z$$
$$z' = -y$$
$$y(0) = 0$$
$$z(0) = y'(0) = 1$$

This can be written in vector-form to simplify it:
$$\mathbf{v} = [y, z]^T$$
$$\mathbf{v}' = [z, -y]^T$$
$$\mathbf{v}(0) = [0, 1]^T$$

Now we can write a function which takes as input a $\mathbf{v}$ and returns the derivative of them.
This function can be represented as a matrix multiplication, $\mathbf{v}' = A\mathbf{v}$, with a matrix $A$:
$$A = \begin{bmatrix}0 & 1\\\\-1 & 0\end{bmatrix}$$

Let us code this function but let us also take this opportunity to explore the `NumContext` to pass in `A`.
"""

nbCode:
  proc dv(t: float, y: Tensor[float], ctx: NumContext[Tensor[float], float]): Tensor[float] =
    ctx.tValues["A"] * y

nbText: hlMd"""
`NumContext` consists of two tables, `ctx.fValues` which can contain `float`s and `ctx.tValues` which in this case can hold
`Tensor[float]`. So we access `A` which we will insert when creating the context variable:
"""

nbCode:
  var ctx = newNumContext[Tensor[float], float]()
  ctx.tValues["A"] = @[@[0.0, 1.0], @[-1.0, 0.0]].toTensor

nbText: hlMd"""
Now we are ready to setup and run the simulation as we did previously:
"""

nbCodeInBlock:
  let t0 = 0.0
  let tEnd = 20.0
  let y0 = @[@[0.0], @[1.0]].toTensor # initial condition
  let tspan = linspace(t0, tEnd, 50)
  let odeOptions = newODEoptions(tStart = t0)

  let (t, y) = solveOde(dv, y0, tspan, odeOptions, ctx=ctx, integrator="tsit54")
  let yEnd = y[^1][0, 0]
  let error = abs(yEnd - sin(tEnd))
  echo "Error: ", error

nbText: """
The error is nice and low. The error for the other methods are along with the timings:
"""

for m in concat(fixedODESubset, adaptiveODESubset):
  let t0 = 0.0
  let tEnd = 20.0
  let y0 = @[@[0.0], @[1.0]].toTensor # initial condition
  let tspan = linspace(t0, tEnd, 50)
  let odeOptions = newODEoptions(tStart = t0)

  let (t, y) = solveOde(dv, y0, tspan, odeOptions, ctx=ctx, integrator=m)
  let yEnd = y[^1][0, 0]
  let error = abs(yEnd - sin(tEnd))
  nbText: &"- {m}: {error:e}"

block:
  let t0 = 0.0
  let tEnd = 20.0
  let y0 = @[@[0.0], @[1.0]].toTensor # initial condition
  let tspan = linspace(t0, tEnd, 50)
  let odeOptions = newODEoptions(tStart = t0)
  nbCode:
    for m in concat(fixedODESubset, adaptiveODESubset):
      benchy.timeIt m:
        keep solveOde(dv, y0, tspan, odeOptions, ctx=ctx, integrator=m)

  nb.blk.code = ""

nbText: hlMd"""
We can once again see that the high-order adaptive methods are both more accurate and faster than the fixed-order ones.

## Further reading
- [numericalnim's documentation on ODEs](https://scinim.github.io/numericalnim/numericalnim/ode.html)
"""

nbSave