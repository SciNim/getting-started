# Package
version       = "0.1.0"
author        = "SciNim contributors"
description   = "SciNim getting started examples"
license       = "MIT"
skipDirs      = @["books"]

# Dependencies
requires "nim >= 1.2.0"
requires "nimib"
requires "ggplotnim"

import os
task genbook, "genbook":
  for kind, path in walkDir("books"):
    # This can be used to generate an index.html ?
    if kind == pcFile:
      let (dir, name, ext) = path.splitFile()
      if ext == ".nim":
        selfExec("r " & path)
    if kind == pcDir: discard
  let cmdRsync = "rsync -a --exclude \"*.gitignore\" --exclude \"*.nim\" books/ docs/"
  exec(cmdRsync)
