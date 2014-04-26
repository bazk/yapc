#!/usr/bin/env python2

import sys
import re

if __name__=="__main__":
    if (len(sys.argv) != 2):
        print >> sys.stderr, "Usage:\n\t%s INPUT" % (sys.argv[0],)
        sys.exit(1)

    try:
        with open(sys.argv[1], 'r') as f:
            for line in f:
                line = line.replace('\n', '')

                m = re.match("^([\t ]*)write[\t ]*\((.*)\)(.*)$", line)

                if not m:
                    print line
                    continue

                begin = m.group(1)
                mid = m.group(2)
                end = m.group(3)

                level = 0
                params = []
                tmp = ''
                for c in mid:
                    if c == '(':
                        level += 1
                    elif c == ')':
                        level -= 1

                    if (c == ',') and (level == 0):
                        params.append(tmp)
                        tmp = ''
                    else:
                        tmp += c

                if tmp != '':
                    params.append(tmp)

                for p in params[:-1]:
                    print begin, 'writeln('+p+');'
                print begin, 'writeln('+params[-1]+')'+end

    except IOError:
        print >> sys.stderr, "error: cannot open %s for reading" % (sys.argv[1],)
        sys.exit(2)
