import nimibook

var book = newBookFromToc("SciNim Getting Started", "book"):
  section("Introduction", "index"): discard
  section("Basic topics", "basics/index"):
    entry("Common datatypes", "common_datatypes")
    entry("Data wrangling with dataframes", "data_wrangling")
    entry("Plotting", "basic_plotting")
  section("Numerical methods", "numerical_methods/index"):
    entry("Curve fitting", "curve_fitting")
  section("Data visualization", "data_viz/index"):
    entry("Plotting data", "plotting_data")


book.git_repository_url = "https://github.com/SciNim/getting-started"
nimibookCli(book)
