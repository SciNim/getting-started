let nbSrcDir = nbHomeDir / "../books".RelativeDir
nbDoc.filename = (changeFileExt(nbThisFile, ".html").relativeTo nbSrcDir).string
nbDoc.context["here_path"] = (nbThisFile.relativeTo nbSrcDir).string
nbDoc.context["title"] = nbDoc.context["here_path"]
nbDoc.partials["header_center"] = "<code>" & nbDoc.context["title"].castStr & "</code>"
nbDoc.context["home_path"] = (nbSrcDir.relativeTo nbThisDir).string
