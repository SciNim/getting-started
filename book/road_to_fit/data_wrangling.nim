import nimib, nimibook
import datamancer

nbInit()
nbUseNimibook

# in case nimib #59 is merged this isn't needed anymore
template nbCodeBlock(body: untyped): untyped =
  block:
    nbCode:
      body

nbText: """
# Data wrangling using dataframes from [Datamancer](https://github.com/SciNim/Datamancer)

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
nbText: """
which creates a data frame with three columns named `"s1", "s2", "s3"`. We can see that
mixing different input types is not a problem. The supported types are
- `float`
- `int`
- `string`
- `bool`

and a mix of them in one in one column.

If one wishes to name the columns differently from construction (they can be renamed later
as well), it is done by:
"""
nbCode:
  let df3 = seqsToDf({"Id" : s1, "Word" : s2, "Number" : s3})
  echo df3
nbText: """

Printing a data frame by default prints the first 20 rows. This can be adjusted by calling
the `pretty` procedure manually and handing the number of rows (-1 for all).

In addition one can always view a data frame in the browser by doing `showBrowser(df)` where
`df` is the data frame to view.

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
nbCodeBlock:
  let df = seqsToDf({"x" : @[1, 2, 3], "y" : @[4.0, 5.0, 6.0]})
  let t1: Tensor[int] = df["x", int] # this is a no-op
  let t2: Tensor[float] = df["x", float] # converts integers to floats
  let t3: Tensor[float] = df["y", float] # also a no-op
  let t4: Tensor[string] = df["x", string] # convert to string
  # let t5: Tensor[bool] = df["x", bool] # would produce a runtime error
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
nbCode:
  let df = seqsToDf({"x" : @[1, 2, 3], "y" : @[4.0, 5.0, 6.0]})
  echo df["x", int].sum
  echo df["y", float].mean
nbText: """
and in that sense any operation acting on tensors can be used.

## Perform operations

Many different operations are supported, but can be grouped into a few general procedures.

For a thourough overview of the API, see the [Datamancer documentation](https://scinim.github.io/Datamancer/datamancer.html)

A few common operations:
"""
nbCode:
  echo df3.head(1) # print first row
  echo df3.tail(1) # print last row
  echo df3["Word", string] # access tensor of `Word` column
  echo df3["Number", float].mean # access number column as float and compute mean
  echo df3.mutate(f{"Id+Number" ~ `Id` + `Number`}) # compute new column of id + number
  echo df3.filter(f{`Word` == "hello"}) # filter rows that match column `Word` is "hello"
nbText: """
and much more.
"""

nbSave
