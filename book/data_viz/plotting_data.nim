import nimib, nimibook
import ggplotnim

nbInit()
nbUseNimibook

nbText: """
# Plotting data using [ggplotnim](https://github.com/Vindaar/ggplotnim)

In this tutorial we will introduce `ggplotnim`, a Nim plotting library heavily inspired
by the great R library [ggplot2](https://ggplot2.tidyverse.org).

This will be kept rather brief, but we will discuss the philosophy of the syntax, look
at a reasonably complex plotting example that we deconstruct and finish of by (hopefully)
coming to the conclusion that the ggplot-like syntax is rather elegant.

For this tutorial you should have read the data wrangling introduction to `Datamancer` or
know about data frames and have seen the `Datamancer` formula macro `f{}`.

## On philosophy and graphics

Similar to most areas of life touched by more than a few people who seemingly all have
their own ideas about the right way to do things, plotting libraries come in different
shapes and forms. In terms of their output formats, choice of colors and style and
of most importance for us here: in terms of their API / the programming syntax used.

Most plotting libraries fall into a category that are either focused on object orientation
(your commands return some objects for you to modify to your needs) or a generally imperative
style (call this function `plotFoo` for plot style A, that function `plotBar` for style B,
etc.) and often some combination of these two.

`ggplot2` and as a result `ggplotnim` follow a declarative style that builds up a plot
from a single command by combining multiple different layers as a chain of commands.

This is because `ggplot2` is an implementation of the so called "grammar of graphics".
It's the NixOS of plotting libraries. Tell it what you want and it gets it done for you,
as long as you speak its language.

## The 3 (or 4) basic building blocks of a "ggplot" plot

There are 3 (in some respect 4) major pieces that make up the basic syntax of *every single*
plot created by `ggplot2` or `ggplotnim`. We will quickly go through these now. Keep
in mind that every option that might be automatically deduced can always be overridden.

### Input data

The zeroth piece (hence maybe 4) of a ggplot plot is the input data. It *always* comes
in the form of a `DataFrame` that contains the data to be plotted (or at least the data
from which the thing to be plotted can be computed from, more on that later). If not
overridden manually the columns that are to be plotted define the labels for
the axes in the final plot.

In addition the library will determine automatically (based on column types & heuristic
rules) whether each column to be plotted is continuous or discrete. Continuity and discreteness
are a major factor in the kinds of plots we may create (and how they are represented).

So for the next sections let's say we have some input data frame `df`.

### The `ggplot` procedure

The first proper piece of *every* plot is a call to the `ggplot` procedure. It has a rather
simple signature (note: we drop 2 arguments here, as they are left over in the code for "historical"
reasons, namely `numX/YTicks`):

```nim
proc ggplot*(data: DataFrame, aes: Aesthetics = aes(), …): GgPlot =
```

The first argument is the aforementioned input `DataFrame`. With our data frame, we can
write down the first piece of every plot we will create:

```nim
ggplot(df, …)
```

Simple enough. This doesn't do anything interesting yet. That's what the `aes` is for.

### `aes` - Aesthetics

The `aes` argument of the `ggplot` procedure is the first deciding piece of our plotting
call. It will essentially determine *what* we wish to plot and to some extend *how* we
want to plot it.

"Aesthetics" are the name for the description of the "aesthetic description" about which
data to use for what visible purpose. This might sound abstract, but will become clear
in a few seconds.

For the simplest cases (a scatter or line plot, a histogram, ...) we simply hand a (or multiple)
column(s) to draw. Depending on whether a column contains discrete or continuous data decides
how the axis (or additional scale) will be laid out.

To construct such an `Aesthetic` argument the `aes` macro is used (it's a macro and not a
procedure so that we don't need N generic arguments). It can take the following
arguments:

- `x`
- `y`
- `color`
- `fill`
- `shape`
- `size`
- `xmin`
- `xmax`
- `ymin`
- `ymax`
- `width`
- `height`
- `text`
- `weight`
- `yridges`

quite the list!

Taking a closer look at the kind of arguments gives us maybe an inkling of what it's all about.
The argument either maps to a physical axis in the plot (x, y), a "style"-like thing (color,
fill, shape, size) or some more "descriptive" thing (e.g. for sizes x/yMin/Max, width, height),
and finally some slightly "special" ones (text, weight, yridges).

What each of these mean for the final plot (again) depends on the data being discrete or continuous.

As an example:
- Discrete, each discrete value:
  - x and y: has one tick along x or y
  - color: has one color
  - shape: has one shape
  - size: has one size
- Continuous, each value:
  - x and y: map to a continuous range between min and max values
  - color and fill: has a color picked from a continuous color range
  - size:  has a size picked from a continuous range between smallest and largest size
  - shape: not supported, there are no "continuous shapes"

(for the other aesthetics also only either discrete or continuous make sense. For instance "text" is
always a discrete input, it's used to draw text onto a plot. yridges is to create a discrete ridgeline
plot, etc.)

How these are finally applied still depends on what comes later in the plotting syntax. But in principle
the mapping to more specific things to be drawn is natural. For a point plot the size determines the point
size and the color the point color. For a line it's line width and color and so on.

This part of the ggplot construction might be the most "vague" at first. But with it we can
now continue our construction. Assume our data frame `df` has columns "x" and "y" (continuous),
"Type" (discrete).

```nim
ggplot(df, aes("x", "y", fill = "Type", color = "Type"))
```

## plot something

And plot something!
"""

nbText: """
"""

nbSave
