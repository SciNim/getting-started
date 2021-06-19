import nimibook

var book = newBookFromToc("SciNim Getting Started", "book"):
  section("Introduction", "index"): discard
  section("From data types to curve fitting", "road_to_fit/index"):
    entry("Common datatypes", "common_datatypes")
    entry("Data wrangling with dataframes", "data_wrangling")
    entry("Plotting data", "plotting_data")
    entry("Curve fitting", "curve_fitting")
  section("Data visualization", "data_viz/index"):
    entry("Plotting", "basic_plotting")

book.git_repository_url = "https://github.com/SciNim/getting-started"
nimibookCli(book)
