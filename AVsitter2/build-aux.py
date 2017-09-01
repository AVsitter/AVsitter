#!/usr/bin/env python
# coding: utf8

import sys, re

def prterr(s):
    sys.stderr.write(s + "\n")

def main(argc, argv):
    if argc < 2:
        prterr(u'Need exactly 1 argument (input filename)')
        return 1

    # Regex that replaces a line with its OSS version when one's specified.
    os_re = re.compile(r'^( *)(.*?)// ?OSS::(.*)$', re.MULTILINE)

    f = open(argv[1], "r");
    s = f.read()
    f.close()
    # The U+FFFD character that AVsitter uses causes problems in OpenSim.
    # Replace it with U+001F (Unit Separator) which works fine.
    s = s.replace(b'\xEF\xBF\xBD', b'\x1F')

    # UUIDs in OpenSim
    s = s.replace('f2e0ed5e-6592-4199-901d-a659c324ca94', '206fcbe2-47b3-41e8-98e6-8909595b8605')
    s = s.replace('b30c9262-9abf-4cd1-9476-adcf5723c029', 'b88526b7-3966-43fd-ae76-1e39881c86aa')
    # TODO: Replace LockGuard texture UUIDs

    s = os_re.sub(r'\1\3', s)
    sys.stdout.write(s)
    return 0

ret = main(len(sys.argv), sys.argv)
if ret is not None and ret > 0:
    sys.exit(ret)
