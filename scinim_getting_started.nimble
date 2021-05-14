# Package
version       = "0.1.0"
author        = "SciNim contributors"
description   = "SciNim getting started examples"
license       = "MIT"
skipDirs      = @["books"]
skipFiles = @["nbPostInit.nim"]

# Dependencies
requires "nim >= 1.2.0"
requires "nimib#main"
requires "ggplotnim"

import os
task genbook, "genbook":
  # TODO generate an index.html file that's not hardcoded
  for path in walkDirRec("books"):
    let (dir, name, ext) = path.splitFile()
    if ext == ".nim":
      echo "exec(" & path & ")"
      selfExec("r " & path)
