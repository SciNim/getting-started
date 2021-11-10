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
requires "nimib >= 0.2.3"
requires "nimibook >= 0.2.1"
requires "ggplotnim >= 0.4.2"
requires "datamancer >= 0.1.6"
requires "mpfit"
requires "numericalnim"
requires "unchained#head"
requires "benchy"
requires "scinim >= 0.2.2"
requires "nimpy >= 0.2.0"
requires "nimjl >= 0.6.3"


task genbook, "build book":
  exec("nimble build -d:release")
  exec("./bin/getting_started init")
  exec("./bin/getting_started build")
