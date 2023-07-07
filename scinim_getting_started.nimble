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
requires "nimib"
requires "nimibook"
requires "ggplotnim == 0.5.6"
requires "datamancer >= 0.2.1"
requires "mpfit"
requires "numericalnim >= 0.7.1"
requires "unchained >= 0.1.9"
requires "benchy"
requires "scinim >= 0.2.2"
requires "nimpy >= 0.2.0"
requires "nimjl >= 0.6.3"


task genbook, "build book":
  exec("nimble build -d:release")
  exec("./bin/getting_started init")
  exec("./bin/getting_started build")
