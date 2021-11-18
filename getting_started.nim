import nimibook

var book = newBookFromToc("SciNim Getting Started", "book"):
  section("Introduction", "index"): discard
  section("Basic topics", "basics/index"):
    entry("Common datatypes", "common_datatypes")
    entry("Data wrangling with dataframes", "data_wrangling")
    entry("Plotting", "basic_plotting")
    entry("Machine Learning", "machine_learning")
    entry("Units", "units_basics")
  section("Numerical methods", "numerical_methods/index"):
    entry("Curve fitting", "curve_fitting")
    entry("Integration (1D)", "integration1d")
  section("Data visualization", "data_viz/index"):
    entry("Plotting data", "plotting_data")
  section("Interfacing with other language", "external_language_integration/index"):
    entry("Nimpy - The Nim Python bridge", "nim_with_py")
    section("Nimjl - The Nim Julia bridge", "julia/basics"):
      entry("Advanced types", "nimjl_conversions")
      entry("Julia Arrays from Nim", "nimjl_arrays")
    entry("Interfacing with R", "nim_with_R")



book.git_repository_url = "https://github.com/SciNim/getting-started"
book.plausible_analytics_url = "scinim.github.io/getting-started"
nimibookCli(book)
