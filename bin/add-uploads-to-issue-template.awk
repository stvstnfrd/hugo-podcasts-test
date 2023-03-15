#!/usr/bin/awk -f
# body[feed_title_clean]:attributes.option

BEGIN {
    looking = 1
    delete keys[0]
    count = 0
    for (i=2; i<=ARGC; i++) {
        if (ARGV[i] != "") {
            value = ARGV[i]
            keys[i-1] = value
            count += 1
        }
        delete ARGV[i]
    }
}

looking == 1 && /^body/ {
    looking += 1
}

looking == 2 && /^ *id: *attachment$/ {
    looking += 1
}

looking == 2 && /^ *id: *artwork$/ {
    looking += 1
}

looking == 3 && /^ *attributes: *$/ {
    looking += 1
}

looking == 4 && /^ *options: */ {
    if (count == 0) {
        eol = " []"
    } else {
        eol = ""
    }
    print "      options:" eol
    for (i in keys) {
        print "      - '" keys[i] "'"
    }
    looking += 1
    next
}

looking == 5 && /^      -/ {
    next
}

looking == 5 && ! /^    -/ {
    looking = 2
}

{
    print
}
