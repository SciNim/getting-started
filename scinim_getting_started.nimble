# Package
version       = "0.1.0"
author        = "SciNim contributors"
description   = "SciNim getting started examples"
license       = "MIT"
skipDirs      = @["books"]
skipFiles = @["nbPostInit.nim"]

# Dependencies
requires "nim >= 1.2.0"
requires "nimib#486c22d9cd9c40f32f00efe9fd46630b9bd4d3c7"
requires "ggplotnim"

import os
task genbook, "genbook":
  # TODO generate an index.html file that's not hardcoded
  for path in walkDirRec("books"):
    let (dir, name, ext) = path.splitFile()
    if ext == ".nim":
      selfExec("r " & path)
