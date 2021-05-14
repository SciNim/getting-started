# Package
version       = "0.1.0"
author        = "SciNim contributors"
description   = "SciNim getting started examples"
license       = "MIT"
skipDirs      = @["books"]

# Dependencies
requires "nim >= 1.2.0"
requires "nimib#486c22d9cd9c40f32f00efe9fd46630b9bd4d3c7"
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
    liElements &= &"<li><a href=\"{path}\">{name}</a></li>\n"
  liElements &= "</ul>"
  writeFile("books/toc.mustache", liElements)
  for (path, name) in nimFilePaths:
    selfExec("r " & "books/" & path)
