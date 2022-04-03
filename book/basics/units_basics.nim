import nimib, nimibook

nbInit(theme = useNimibook)
nb.useLatex

nbText: """
# Using and checking units with [Unchained](https://github.com/SciNim/Unchained)

Units are crucial in physics, without them we wouldn't have any consistent way of comparing two measurements. 
You don't solve an equation without checking units afterwards as a safety-check. But when it comes to coding 
physical formulas, units are often ignored or in best cases in a comment somewhere. This can be solved by using
unit libraries like `Unchained`. What puts `Unchained` apart from many other libraries is that it does the majority
of the work at compile-time so that you know that if the code compiles, then the units are correct. 

Many other libraries check this at runtime, and they only complain when they run the piece of code they want to check
the units of. As an added bonus, doing most of the work when compiling the code will make the code run faster as there will at most
be a conversion factor injected.

## Motivating example

One example of a real disaster caused by conversion errors is the Mars Climate Orbiter that NASA sent to the red planet in 1999. 
It crashed. Why? Because the navigators at JPL used metric units while the manufacturers had used imperial units. So when
the navigators thought they read 1 N⋅s from the craft's sensors it was in fact 1 lbf⋅s.

As an introduction to `Unchained`, let's find out what 1 lbf⋅s is in N⋅s to understand how much of a difference it made.
"""
nbCode:
  import unchained

  ## Define composite units
  defUnit(N•s)
  defUnit(lbf•s)

  ## Assign variables
  let lbfs = 1.lbf•s
  let Ns = lbfs.to(N•s)

  echo lbfs, " equals ", Ns

nbText: """
As you can see, they thought the value they read was 4.4 times smaller than it really was! 

But what does the code do? Let's dissect it block-by-block:

1. `defUnit(N•s)` - There are a ridiculous amount of combinations of base units.
Therefore you must define composite units manually before you use them. More on this in a later section.
2. `let lbfs = 1.lbf•s` - We use the dot (`.`) to assign a unit to a number. In this case we assign a variable with the value "1 lbf•s".
3. `let Ns = lbfs.to(N•s)` - We use the `to` proc to convert a variable from one unit to another.
"""

nbText: """
## Defining and assigning units

The first thing you probably will want to do is to associate a value with a unit, for example 1 Newton. There are multiple ways
to specify a unit, both short and long versions:
"""

nbCodeInBlock:
  ## Short version
  let n1 = 1.N
  ## Long version
  let n2 = 1.Newton
  ## Short version with prefix (milli)
  let n3 = 1.mN
  ## Long version with prefix
  let n4 = 1.MilliNewton

nbText: """
That was easy enough, and being able to use prefixes makes for a saner user experience. Forgetting to multiply by the
correct prefix factor is a very common mistake after all. This is solved by including prefixes directly in the library,
so you don't have to deal with them manually.

When it comes to composite types it gets a bit more complicated though. For example if we want to use a unit `kg•m•s⁻¹` we
have a few more things to consider. First and foremost, composite types must either be defined in a `defUnit` or be used in a
dot expression (eg `10.kg•m•s⁻¹`) *before* it can be used in other parts of the code. Here are a few valid and invalid cases:
"""

nbCodeInBlock:
  ## Correct way of doing it!
  defUnit(kg•m•s⁻¹)
  proc unitProc(k: kg•m•s⁻¹) =
    echo k

nbText: """
```nim
## Incorrect way of doing it! Missing `defUnit`
proc unitProc(k: kg•m•s⁻¹) =
  echo k
```
"""

#[
nbCodeInBlock:
  ## Correct way of doing it!
  let a = 5.kg•m•s⁻¹
  proc unitProc(k: kg•m•s⁻¹) =
    echo k

nbText: """
```nim
## Incorrect way of doing it! Missing first use in `.`
proc unitProc(k: kg•m•s⁻¹) =
  echo k
```
"""

]#

nbText: """
There is also the `UnitLess` type which represents a quantity without a unit like for example a count or a percentage.
It is used like the other units with the addition that `UnitLess` numbers can be passed to procs accepting `float`.
This is done through converters behind the scenes, so you don't have to manually convert between the two: 
"""

nbCodeInBlock:
  proc f(x: float): float = x*x + x + 1
  let ul = 100.UnitLess
  echo f(ul)
  ## This will fail beacuse `x` isn't UnitLess:
  ## let x = 100.kg
  ## echo f(x)

nbText: """
To get the unit of a variable you can use `typeof` and checking units is done using `is`:
"""

nbCodeInBlock:
  let mass = 10.kg
  echo typeof(mass) is kg

nbText: """
### Different ways to write units
As you might have noticed, we used a few unicode characters in the code above (•, ⁻¹). Most keyboard don't have these symbols on them but
there are ways to work around that. On Linux you could check if your distro supports the "Compose key" which lets you use sensible
key combinations to type symbols. For example `²` can be written using `Compose + ^ + 2`, it makes sense! 

On Windows there is WinCompose which tries to emulate the compose key. There is also the Emoji/Symbols popup menu
when you press `Windows + .` where you can find a multitude of symbols. 

If you don't want to use these kind of (totally awesome) tools,
you can also write the types in backticks (``` ` ```) and use `*` and `^`
instead (`/` is not allowed, use negative exponents instead). 
Here are a few examples of equivalent ways of writing the same unit:
"""

nbCodeInBlock:
  let unicodeUnit = 1.kg•m•s⁻¹
  let textUnit = 1.`kg*m*s^-1`
  echo unicodeUnit == textUnit

nbCodeInBlock:
  let unicodeUnit = 1.N•s
  let textUnit = 1.`N*s`
  echo unicodeUnit == textUnit

nbText: """
### Arithmetics with units
Units can of course be used in formulas. The supported operators are `+`, `-`, `*`, `/` and `^` (Note: `^` only work with integer exponents!). 
You don't have to `defUnit` the resulting unit of an operation, it's done automatically.
There are a few rules worth remembering, some more obvious than others:

- You can only add and subtract units of the same quantity (hopefully pretty obvious). 
Example: `1.kg + 1.lbs` works. `1.kg + 1.m` doesn't work.
- You can multiply and divide units of different quantities. Example: `1.kg * 1.m` works.
- If it is ambiguious what the resulting unit should be, they are converted to base SI units. Example: `1.kg + 1.lbs` will result in `1.45359 KiloGram`.
- Conversion from prefixed to non-prefixed units only happen if multiple different units or prefixes of the same quantity are mixed.
Example: `1.mm * 1.kg` results in `1 KiloGram•MilliMeter` while `1.mm * 1.cm` results in `1e-005 Meter²`.
- Division by same quantities gives a `UnitLess` result. Example: `1.cm / 1.m` gives `0.01 UnitLess`.

Let's see some actual code now! You are probably familiar with the harmonic oscillator:
$$y(t) = A \cos (ω t + φ)$$
where $ω$ is the frequency in $rad ⋅ s^{-1}$, $φ$ is an angle and $A$ is the maximum amplitude in $cm$.
Let's get coding now!
"""

nbCode: import math
nbCodeInBlock:
  proc y(t: Second): CentiMeter =
    let ω = 100.rad•s⁻¹ ## or 100.`rad*s^-1`
    let A = 10.cm
    let φ = Pi.rad
    let argument = ω * t + φ
    result = A * cos(argument)

  echo y(0.s)



nbSave
