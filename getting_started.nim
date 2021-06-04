import nimibook

var book = newBookFromToc("SciNim Getting Started", "book"):
  section("Introduction", "index"): discard
  section("Data visualization", "data_viz/index"):
    entry("Plotting", "basic_plotting")

book.git_repository_url = "https://github.com/SciNim/getting-started"
nimibookCli(book)

