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
  # TODO generate an index.html file that's not hardcoded
  for path in walkDirRec("books"):
    let (dir, name, ext) = path.splitFile()
    if ext == ".nim":
      selfExec("r " & path)
  # Using rsync will recopy structure excluding gitignore and *.nim files
  # This way we can just recursively execute every Nimib file that will generate html file and commiting the generated html files in docs
  let cmdRsync = "rsync -a --exclude \"*.gitignore\" --exclude \"*.nim\" books/ docs/"
  exec(cmdRsync)
