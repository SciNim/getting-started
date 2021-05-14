# Package
version       = "0.1.0"
author        = "SciNim contributors"
description   = "SciNim getting started examples"
license       = "MIT"
skipDirs      = @["books"]
skipFiles     = @["nbPostInit.nim"]

# Dependencies
requires "nim >= 1.2.0"
requires "nimib#main"
requires "ggplotnim"

import os, strformat
task genbook, "genbook":
  # TODO generate an index.html file that's not hardcoded
  var nimFilePaths: seq[(string, string)]
  for path in walkDirRec("books", relative=true):
    # Path will be relative to "books" so it will be the same path as in "docs".
    # So we should be able to use it as links in TOC
    let (dir, name, ext) = path.splitFile()
    if ext == ".nim":
      nimFilePaths.add (path, name)
  var liElements = "<ul>\n"
  for (path, name) in nimFilePaths:
    let htmlPath = path.split(".")[0] & ".html"
    liElements &= "<li><a href=\"{{> path_to_home}}/" & htmlPath & &"\">{name}</a></li>\n"
  liElements &= "</ul>"
  writeFile("docs/toc.mustache", liElements)
  for (path, name) in nimFilePaths:
    selfExec("r -d:nimibCustomPostInit " & "books/" & path)
