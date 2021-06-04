# Package
version       = "0.1.0"
author        = "SciNim contributors"
description   = "SciNim getting started examples"
license       = "MIT"
skipDirs      = @["book"]
bin           = @["getting_started"]
binDir        = "bin"

# Dependencies
requires "nim >= 1.2.0"
requires "nimibook"
requires "ggplotnim"

task genbook, "build book":
  exec("nimble build -d:release")
  exec("./bin/getting_started init")
  exec("./bin/getting_started build")

