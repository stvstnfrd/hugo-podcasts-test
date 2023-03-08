#!/usr/bin/awk -f
# TODO: Check for arguments in this script, not the Makefile
/^ *<dateModified>.*<\/dateModified> *$$/ {
    print "    <dateModified>" date "</dateModified>"
    next
}

/<\/body>/ {
    print "    <outline text=\"" title "\" type=\"rss\" xmlUrl=\"" feed "\" htmlUrl=\"" website "\" />"
}

{
    print
}
