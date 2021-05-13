let nbSrcDir = nbHomeDir / "../books".RelativeDir
nbDoc.filename = (changeFileExt(nbThisFile, ".html").relativeTo nbSrcDir).string