import nimibook

var book = initBookWithToc:
  entry("Introduction", "index.md")
  entry("Ecosystem overview", "overview/index.md")
  section("Basic topics", "basics/index.md"):
    entry("Common datatypes", "common_datatypes")
    entry("Data wrangling with dataframes", "data_wrangling")
    entry("Plotting", "basic_plotting")
    entry("Units", "units_basics")
  section("Numerical methods", "numerical_methods/index.md"):
    entry("Curve fitting", "curve_fitting")
    entry("Integration (1D)", "integration1d")
    entry("ODEs", "ode")
    entry("Optimization", "optimization")
    entry("Interpolation", "interpolation")
    entry("Bayesian Inference", "bayesian")
  section("Data visualization", "data_viz/index.md"):
    entry("Plotting data", "plotting_data")
  section("Interfacing with other language", "external_language_integration/index.md"):
    entry("Nimpy - The Nim Python bridge", "nim_with_py")
    section("Nimjl - The Nim Julia bridge", "julia/basics"):
      entry("Advanced types", "nimjl_conversions")
      entry("Julia Arrays from Nim", "nimjl_arrays")
    entry("Interfacing with R", "nim_with_R")

nimibookCli(book)
