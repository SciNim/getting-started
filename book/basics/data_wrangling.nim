# cannot import `Value` because it clashes with `mustache.values.Value`. This is fixed for
# Nim version >= 1.5 (fully qualified type for formulas used) but important on < 1.5 (cannot
# fully qualify types there)
import nimib except Value
import nimibook
import datamancer

nbInit()
nbUseNimibook

nbText: """
# Data wrangling using the `DataFrame` from [Datamancer](https://github.com/SciNim/Datamancer)

The third major data type often encountered is a `DataFrame`.

Data frames can be thought of as multiple, named tensors of possibly different types
in one object. A data frame library then is supposed to make working with such data
as convenient and powerful as possible.

In the specific case of Datamancer, the data structure is essentially an
`OrderedTable[string, Column]`, where `Column` is a variant object storing one
of 5 different `Tensor[T]` types.

## Construction of a `DataFrame`

A `DataFrame` from the Datamancer library can be constructed in two different ways. Either
from an input CSV file or from existing sequences or tensors.

Construction from a CSV file is performed using the `readCsv` procedure. It provides multiple
different options (different separators, skipping lines, header symbols, ...), but for a
regular comma separated value file, the defaults are fine.

"""
nbCode:
  import datamancer
  # TODO: add some data files to use for the tutorial?
  # let df1 = readCsv("foo.csv")
  # echo df1
nbText: """

Or if one already has a mix of sequences and tensors of the same length:
"""
nbCode:
  import arraymancer
  let s1 = [1, 2, 3]
  let s2 = @["hello", "foo", "bar"]
  let s3 = @[1.5, 2.5, 3.5].toTensor
  let df2 = seqsToDf(s1, s2, s3)
  echo df2
  echo "Column names: ", df2.getKeys() ## getKeys only returns the column names
nbText: """
which creates a data frame with three columns named `"s1", "s2", "s3"`. We can see that
mixing different input types is not a problem. The supported types are
- `float`
- `int`
- `string`
- `bool`

and a mix of them in one column.

Printing a data frame by default prints the first 20 rows. This can be adjusted by calling
the `pretty` procedure manually and handing the number of rows (-1 for all).

In addition one can always view a data frame in the browser by doing `showBrowser(df)` where
`df` is the data frame to view.

If one wishes to name the columns differently from construction (they can be renamed later
as well), it is done by:
"""
nbCode:
  let df3 = seqsToDf({"Id" : s1, "Word" : s2, "Number" : s3})
  echo df3
nbText: """

Finally, one can also create a `DataFrame` starting from an empty object and
assigning sequences, tensors or scalar values manually:
"""
nbCodeInBlock:
  var df = newDataFrame()
  df["x"] = @[1, 2, 3] ## assign a sequence. This sets the `DataFrame` length to 3
  df["y"] = @[4.0, 5.0, 6.0].toTensor ## assign a tensor. Input now `must` match length 3
  try:
    df["z"] = @[5, 6] ## raises
  except ValueError: discard ## type of exception might change in the future
  df["z"] = constantColumn(1, df.len) ## assign a constant column of integers.
nbText: """

## Accessing data underlying a column

The data stored in a column of a data frame can always be accessed easily. Because the
data is stored in a variant object, the user needs to supply the data type to use to
read the data as. Nim does *not* allow return type overloading, which means we cannot
use the runtime information about the types to return the "correct" tensor. All we can
make sure is that accessing the data with the *correct* type is a no-op.

This has the downside that an invalid type will produce a runtime error. On the upside
it allows us to perform type conversions directly, for instance reading an integer column
as floats or any column as strings.

The syntax is as follows:
"""
nbCodeInBlock:
  let df = seqsToDf({"x" : @[1, 2, 3], "y" : @[4.0, 5.0, 6.0]})
  let t1: Tensor[int] = df["x", int] ## this is a no-op
  let t2: Tensor[float] = df["x", float] ## converts integers to floats
  let t3: Tensor[float] = df["y", float] ## also a no-op
  let t4: Tensor[string] = df["x", string] ## convert to string
  try:
    let t5: Tensor[bool] = df["x", bool] ## would produce a runtime error
  except ValueError: discard ## type of exception might be changed in the future
nbText: """
where we indicate the types explicitly on the left hand side for clarity.

This means we can in principle always access individual elements of a data frame column
by getting the tensor and accessing elements from it. Of course this has some overhead,
but due to reference semantics it is relatively cheap (no data is copied, unless type
conversions need to be performed).

## Computing single column aggregations

As we saw in the previous section, accessing a tensor of a column is cheap. We can
use that to perform aggregations on full columns:
"""
nbCodeInBlock:
  let df = seqsToDf({"x" : @[1, 2, 3], "y" : @[4.0, 5.0, 6.0]})
  echo df["x", int].sum
  echo df["y", float].mean
nbText: """
and in that sense any operation acting on tensors can be used.

## Data frame operations

In the more general case (the reason one uses a data frame in the first place) we
don't want to only consider a single column.

Many different operations are supported, but can be grouped into a few general procedures.

Some of the procedures of Datamancer take so called `FormulaNodes`. They are essentially
a domain specific language to succinctly express operations on data frame columns
without the need to fully refer to them. Their basic construction and usage should become
clear in the code below. The Datamancer documentation contains a much deeper introduction
into the specifics here:

[Formula introduction](https://scinim.github.io/Datamancer/datamancer.html#formulas)

### `select` - Selecting a subset of columns

If we have a data frame with multiple columns we may want to keep only
a subset of these going forward. This can be achieved using `select`:
"""
nbCodeInBlock:
  var df = newDataFrame()
  for i in 0 ..< 100:
    df["x" & $i] = @[1 + i, 2 + i, 3 + i]
  echo df.select("x1", "x50", "x99")
nbText: """
which drops every column not selected.

The inverse is also possible using `drop`:
"""
nbCodeInBlock:
  let df = seqsToDf({"x" : @[1, 2, 3], "y" : @[4.0, 5.0, 6.0], "z" : @["a", "b", "c"]})
  echo df.drop("x")
nbText: """

### `rename` - Renaming a column

`rename`, as the name implies, is used to rename columns. Usage is rather simple. We'll
get our first glance at the `f{}` macro to generate a `FormulaNode` here:
"""
nbCodeInBlock:
  let df = seqsToDf({"x" : @[1, 2, 3], "y" : @[4.0, 5.0, 6.0]})
  echo df.rename(f{"foo" <- "x"})
nbText: """
So we can see that we simply assign `<-` the old name "x" to the new name "foo".

### `arrange` - Sorting a data frame

Often we wish to sort a data frame by one or more columns. This is done using `arrange`.
It can take one or more columns to sort by, where for multiple columns the order
of the inputs decides the precedence of what to sort by first, the later columns only
used to break ties between the former.

The sort order is handled in the same way as in Nim's standard library, i.e. using
an `order` argument that takes either `SortOrder.Ascending` or `SortOrder.Descending`.
The default order is ascending order.
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[4, 2, 7, 4], "y" : @[2.3, 7.1, 3.3, 1.0],
                      "z" : @["b", "c", "d", "a"]})
  echo df.arrange("x") ## sort by `x` in ascending order (default)
  echo df.arrange("x", order = SortOrder.Descending) ## sort in descending order
  echo df.arrange(["x", "z"]) ## sort by two columns, first `x` then `z` to break ties
nbText: """

### `unique` - Removing duplicate rows

Another useful operation is removal of duplicate entries. `unique` is the procedure
to use. If no argument is given uniqueness is determined based on *all* existing
columns. This is not always the most desired option of course, which is why `unique`
accepts a variable number of columns. Then only uniqueness among these columns is
considered.
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[1, 2, 2, 2, 4], "y" : @[5.0, 6.0, 7.0, 8.0, 9.0],
                      "z" : @["a", "b", "b", "d", "e"]})
  echo df.unique() ## consider uniqueness of all columns, nothing removed
  echo df.unique("x") ## only consider `x`, only keeps keeps 1st, 2nd, last row
  echo df.unique(["x", "z"]) ## considers `x` and `z`, one more unique (4th row)
nbText: """

### `mutate` - Creating new or modifying existing columns

`mutate` is the procedure to use to add new columns to a data frame or modify
existing ones. For this procedure we need to hand formulas using the `f{}` macro
again. Here it is advisable to name the formulas. Instead of the above assignment
operator `<-` we now use the "x depends on y" operator `~`.

Further, to refer to a column in the computation we perform we will use accented
quotes. This is all the complexity of that macro we will discuss in this introduction.

Let's compute the sum of two columns to get a feel:
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[1, 2, 3], "y" : @[10, 11, 12] })
  echo df.mutate(f{"x+y" ~ `x` + `y`})
nbText: """
Of course we can use constants and local Nim symbols as well:
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[1, 2, 3]})
  echo df.mutate(f{"x+5" ~ `x` + 5 })
  let y = 2.0
  echo df.mutate(f{"x + local y" ~ `x` + y})
nbText: """
Note: There is a slight subtlety at play here. If you look closely at the output of
these two `mutate` commands you see that in the first case the resulting column is
of type `int`, whereas in the second case it's `float`. That is because the type
of the column is deduced based on the types in the rest of the formula. `5` is an
`int` so `x` is read as integers in the first case, whereas `y` is a `float` and so
`x` is read as a `float`. See the Datamancer documentation on details and how to
specify the types manually.

And as stated we can also overwrite columns:
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[1, 2, 3] })
  echo df.mutate(f{"x" ~ `x` + `x`})
nbText: """

Under the hood these formulas are converted into a closure that takes a data frame
as an input. The column references are extracted and converted into a preamble
that reads the corresponding tensors. Then we run over the relevant tensors and
perform the described operation for each element. The result is assigned to
a resulting tensor, which is assigned as the new column.

The only restriction on the body of the formula is that it's a valid Nim expression
(if one mentally replaces column references by tensor elements) that returns a
value of a valid data type for a data frame.

If one wishes the same behavior as `mutate` but does not require the columns anymore
that are not explicitly created / modified using a formula, there is `transmute` for
this purpose. Otherwise it is equivalent to `mutate`.

### `filter` - Removing rows based on a predicate

These mentioned formulas can of course also return boolean values. In combination
with the `filter` procedure this allows us to remove rows of a data frame that
fail to pass a condition (or a "predicate").
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[1, 2, 3, 4, 5], "y" : @["a", "b", "c", "d", "e"] })
  echo df.filter(f{ `x` < 3 or `y` == "e" })
nbText: """

### `summarize` - Computing aggregations on a full data frame

The approach described in "Computing single column aggregations" can be useful for
simple single column operations, but does not scale well. That's what `summarize` is
for. Here we use the last operator used in the `f{}` macro, namely the reduction
`<<` operator:
"""
nbCodeInBlock:
  let df = seqsToDf({ "x" : @[1, 2, 3, 4, 5], "y" : @[5, 10, 15, 20, 25] })
  echo df.summarize(f{float:  mean(`x`) }) ## compute mean, auto creates a column name
  echo df.summarize(f{float: "mean(x)" << mean(`x`) }) ## same but with a custom name
  echo df.summarize(f{"mean(x)+sum(y)" << mean(`x`) + sum(`y`) })
nbText: """
Keen eyes will notice the `float:` at the beginning of the first two examples. This is
a "type hint" for the formula, because the symbol "mean" is overloaded in Nim. But not
by a few distinct procedures, but generically. At this moment there are no heuristics
involved to choose one type over another in a generic case. Therefore, we don't know
what type `x` should be read as. So we overwrite the input type manually and give the
macro a hint.

If we leave out the type information you will be greeted with a message of the type
information found of `mean` and to consider giving such a type hint.

The situation is slightly different for the last case, in which an addition is involved.
Due to some heuristic rules involving the most basic operators (maths and boolean) we can
determine here that the input is probably supposed to be float.

### `group_by`

`summarize` and the other procedures can be spiced up if used in combination with
`group_by`.

`group_by` by itself doesn't perform any operations. It simply returns a new data frame
with the exact same data that is now "grouped" by one or more columns. These columns should
be columns containing *discrete* data. This grouping can be used (manually or indirectly)
via the `groups` iterator. It yields all "sub data frames" contained in the grouped data
frame. These sub data frames are those of duplicate entries in the columns that we have
grouped by. It essentially yields everything as a sub data frame that would be reduced
to a single row if using `unique` on the same columns as grouped by.

This should become clearer with an example:
"""
nbCodeInBlock:
  let df = seqsToDf({ "Class" : @["A", "C", "B", "B", "A", "C", "C"],
                      "Num" : @[1, 5, 3, 4, 8, 7, 2] })
    .group_by("Class")
  for t, subDf in groups(df):
    echo "Sub data frame: ", t
    echo subDf
nbText: """
We can see we have 3 sub data frames. One for each discrete value found in column `Class`.

The actually interesting applications of `groub_by` though is its combination with one
of the other procedures shown above, in particular `summarize`, `filter` and `mutate`.
For a grouped data frame these operations will then performed *group wise*. Operations
that only use information of a single row are unaffected by this. But any formula that
includes a reference to a full column (`mean, sum, ...`) will compute this value per
group.

A few examples:
- `summarize`
"""
nbCodeInBlock:
  let df = seqsToDf({ "Class" : @["A", "C", "B", "B", "A", "C", "C", "A", "B"],
                      "Num" : @[1, 5, 3, 4, 8, 7, 2, 0, 0] })
  echo df.group_by("Class").summarize(f{int: "sum(Num)" << sum(`Num`)})
nbText: """
  We can see this computes the sum for each class now.
- `filter`:
"""
nbCodeInBlock:
  let df = seqsToDf({ "Class" : @["A", "C", "B", "B", "A", "C", "C", "A", "B"],
                      "Num" : @[1, 5, 3, 4, 8, 7, 2, 0, 0] })
  echo df.group_by("Class").filter(f{ sum(`Num`) <= 9 })
nbText: """
  and again, the filtering is done per group. In this sense a filtering operation
  that uses a reducing formula as input would usually not make too much sense anyway.
- `mutate`:
"""
nbCodeInBlock:
  let df = seqsToDf({ "Class" : @["A", "C", "B", "B", "A", "C", "C", "A", "B"],
                      "Num" : @[1, 5, 3, 4, 8, 7, 2, 0, 0] })
  echo df.group_by("Class").mutate(f{"Num - mean" ~ `Num` - mean(`Num`)})
nbText: """
  where we subtract the mean (of each class!) from each observation.

If one uses multiple columns to group by, we get instead the sub data frame corresponding
to each unique combination of discrete values. Feel free to play around and try out
such an example!

### `gather` - Converting a wide format data frame to long format

As one of the last things to cover, we will quickly talk about data frames in wide and
long format. In a way the example data frame above with a column "Class" and a column
"Num" can be considered a data frame in "long" format. Long format in the sense that
we have one discrete column "Class" that maps to different "Num" values. Because the
column "Class" contains *discrete* values, We can imagine "transposing" the data frame
to columns "A", "B", "C" instead with the values for each of these *groups* as the values
in the corresponding columns. Let's look at:
- this data frame
- the output of grouping that data frame by "Class"
- the same data frame in wide format

for clarity:
"""
nbCodeInBlock:
  let dfLong = seqsToDf({ "Class" : @["A", "C", "B", "B", "A", "C", "C", "A", "B"],
                          "Num" : @[1, 5, 3, 4, 8, 7, 2, 0, 0] })
  echo "Long format:\n", dfLong
  echo "----------------------------------------"
  echo "Grouping by `Class`:"
  for _, subDf in groups(dfLong.group_by("Class")):
    echo subDf
  echo "----------------------------------------"
  let dfWide = seqsToDf({"A" : [1, 8, 0], "B" : [3, 4, 0], "C" : [5, 7, 2]})
  echo "Wide format:\n", dfWide
nbText: """
As we can see, the difference between wide and long format is the way the `groub_by` results
are "assembled". As different columns for each group (wide format) or as two (key, value)
columns (long format).

The conversion from wide -> long format is always possible. But the the mapping of long -> wide
format requires there to be the the same number of entries for each class. If that condition
is not satisfied, there will be missing values in the columns of the separate classes.

Depending on circumstances one might have input data in either order. However, in particular
for plotting purposes the long format is often more convenient as it allows to classify the
discrete classes using different colors, shapes etc. automatically.

Therefore, there is the `gather` procedure to convert a wide format data frame into a
long format one. It takes the columns to be "gathered", the name of the column containing
the "keys" (the column from which a value came) and a name for the column of the "values"
that were "gathered". We can use it to recover the ("Class", "Num") data frame from
the last one:
"""
nbCodeInBlock:
  let df = seqsToDf({"A" : [1, 8, 0], "B" : [3, 4, 0], "C" : [5, 7, 2]})
  echo df.gather(df.getKeys(), ## get all keys to gather
                 key = "Class", ## the name of the `key` column
                 value = "Num")
nbText: """
which is exactly the same data frame as in the examples before.

(Note: the inverse procedure to convert a long format data frame back into wide format
is currently still missing. It will be added soon)

### `innerJoin` - joining two data frames by a common column

As the last common example of data frame operations, we shall consider joining two
data frames by a common column.
"""
nbCodeInBlock:
  let df1 = seqsToDf({ "Class" : @["A", "B", "C", "D", "E"],
                       "Num" : @[1, 5, 3, 4, 6] })
  let df2 = seqsToDf({ "Class" : ["E", "B", "A", "D", "C"],
                       "Ids" : @[123, 124, 125, 126, 127] })
  echo innerJoin(df1, df2, by = "Class")
nbText: """
where we joined two data frames by the "Class" column, resulting in a data frame with
3 columns. The matching rows for the classes were put together aligning corresponding
"Num" and "Ids" values.

Of course joining two data frames is only a sensible option for a column containing
discrete data so that equal elements in that column for both input data frames can
be found.

This already covers the *majority* of the API of Datamancer. There are more procedures,
but the presented ones should be all that is needed in the vast majority of use cases.

Check out the [Datamancer documentation](https://scinim.github.io/Datamancer/datamancer.html)
for a full picture and in particular for a better and more thorough introduction to the
formula syntax.
"""
nbSave
