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

## A motivating example

Let's now consider a somewhat complicated plotting example. Using that we will look at why
it is called a *grammar* of graphics.
"""
nbCodeInBlock:
  ## ignore the dummy `df` here. This is to be able to compile the code (we throw away
  ## the `ggplot` result as we don't call `ggsave`)
  let df = seqsToDf({"Energy" : @[1], "Counts" : @[2], "Type" : @["background"]})
  discard ggplot(df, aes("Energy", "Counts", fill = "Type", color = "Type")) +
    geom_histogram(stat = "identity", position = "identity", alpha = some(0.5), hdKind = hdOutline) +
    geom_point(binPosition = "center") +
    geom_errorbar(data = df.filter(f{`Type` == "background"}),
                  aes = aes(yMin = f{max(`Counts` - 1.0, 0.0)}, yMax = f{`Counts` + 1.0}),
                  binPosition = "center") +
    xlab("Energy [keV]") + ylab("#") +
    ggtitle("A multi-layer plot of a histogram and scatter plot with error bars")
nbText: """
It may seem overwhelming. But it's actually simple and can be read from top to bottom.
In words all this says is:

"Create a plot from the input data frame `df` using column 'Energy' for the x axis, 'Counts'
for the y axis and color the data (both outline `color` and fill color `fill`) based on the
discrete entries of column 'Type'. With it draw:
- a histogram without statistical computations (`stat = "identity"`, i.e. don't *compute* a histogram
  but use the data as a continuous bar plot), draw them in identity position (where the data says,
  no stacking of bars), add some alpha to the color and draw it as an outline.
- a scatter plot in the center positions of each bin (`binPosition = "center"`), as the data
  contains bin edges.
- errorbars for all data of type 'background' (`data = df.filter(…)`), where the error bars range
  from 'yMin' to 'yMax' for all points, also in center position.
Finally, customize x (`xlab`) and y (`ylab`) labels and add a title (`ggtitle`)."

The only thing we left out is the `ggsave` call, as we only have a dummy data frame here. We
will now walk through the basic building blocks of every plot and then look at the above as
an actual plot. After reading the next part looking at the plot above again should make it seem
less dense already.

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
now continue our construction. Assume our data frame `df` has columns "Energy" and "Counts" (continuous),
"Type" (discrete).

```nim
ggplot(df, aes("Energy", "Counts", fill = "Type", color = "Type"))
```

If you paid close attention to the plot example above, you will have noticed that for `yMin` and `yMax`
we did not actually hand a column, but rather a `ggplotnim` formula. This is the main reason `aes` is
a macro. You can hand *any* formula that references local variables or column references, or simply
assign constant values (`aes(width = 5)` is perfectly valid). `ggplotnim` will compute the resulting
values for you automatically before plotting.

### `geoms` - Geometric shapes to fill a plot

Input data and aesthetics of course are not enough to actually draw a plot. So far we have only
stated what part of the data to use and added a discrete classification by one column (fill
and color the "Type" column).

In a sense this has described our coordinate system so far (from the continuity or discreteness)
we can determine the ranges / classes for each axis, same for the colors. Now we need to tell
the plot what to apply this to.

This is where the layering structure of `ggplot` actually becomes apparent, because now we
will just list all kinds of `geoms` we wish to draw. The order we list them directly determines
the order they are drawn in (the later ones are drawn on top of the former ones, which is important
to remember for more busy plots).

This is what all available `geom_*` procedures are for. They return `Geom` variant objects that mainly
just store their kind and possibly some specific information required to draw them.

The (currently) implemented geoms are as follows (with the required aesthetics listed):
- `geom_point`: draw points for each `x`/`y`
- `geom_line`: draw a line through all `x`/`y`
- `geom_errorbar`: draw error bars from `xMin` to `xMax` or `yMin` to `yMax` at `x`/`y`
- `geom_linerange`: draw lines from `xMin` to `xMax` or `yMin` to `yMax`
- `geom_bar`: draw a *discrete* bar plot using the occurrences (default `stat = "count"`) of each
   discrete value in `x` or the number of counts indicated in `y` (`stat = "identity"`)
- `geom_histogram`: draw a *continuous* bar plot computing a histogram from continuous variable `x`
   (default `stat = "bin"`) or draw continuous bars starting at `x` and the number of entries
   indicated in `y` (`stat = "identity"`).
- `geom_freqpoly`: same as `geom_histogram`, but connect bin centers by lines instead of drawing bars
- `geom_tile`: draw discrete tiles at `x`/`y` (default position bottom left) with width `width` and height
  `height` each. Tiles don't need to touch.
- `geom_raster`: draw fully connected tiles at `x`/`y` of `width` and `height`. `width` and `height` must
   be constant!
- `geom_text`: draw text at `x`/`y` containing `text` (the `text` aesthetic)

Here we stated mainly the *typical* (or default) use cases. All geoms take all arguments. That means
you can also draw a histogram using points by applying the `stat = "bin"` argument. The difference
is just in the defaults! Or in case of a `geom_histogram` call you can indicate that the `binPosition`
should be `"center"` instead of the default `"left"` to have `x` indicate the bin centers.

The possibilities are almost endless. You can combine any geom with (almost) any option and
it *should just work* (few exceptions exist, e.g. `geom_raster` only draws fixed size tiles for performance).

## Another look at *that* plot

Let's look at the plot from above again. This time read the command with the gained knowledge and then
see if the explanation in words makes more sense now.
"""
nbCode:
  import ggplotnim, random, sequtils
  let df = seqsToDf({ "Energy" : cycle(linspace(0.0, 10.0, 25).toRawSeq, 2),
                      "Counts" : concat(toSeq(0 ..< 25).mapIt(rand(10.0)),
                                        toSeq(0 ..< 25).mapIt(rand(10).float)),
                      "Type" : concat(newSeqWith(25, "background"),
                                      newSeqWith(25, "candidates")) })
  ggplot(df, aes("Energy", "Counts", fill = "Type", color = "Type")) +
    geom_histogram(stat = "identity", position = "identity", alpha = some(0.5), hdKind = hdOutline) +
    geom_point(binPosition = "center") +
    geom_errorbar(data = df.filter(f{`Type` == "background"}),
                  aes = aes(yMin = f{max(`Counts` - 1.0, 0.0)}, yMax = f{`Counts` + 1.0}),
                  binPosition = "center") +
    xlab("Energy [keV]") + ylab("#") +
    ggtitle("A multi-layer plot of a histogram and scatter plot with error bars") +
    ggsave("images/multi_layer_histogram.png")

nbImage("images/multi_layer_histogram.png")

nbText: """

Maybe things have become a bit less confusing now.
"""

nbSave
