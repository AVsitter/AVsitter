#!/usr/bin/env python
# coding: utf8

import sys

def prterr(s):
    sys.stderr.write(s + "\n")

def usage():
    """Show usage help."""
    prterr(u"""Usage:
python build-aux.py <command> [<args>]

Where command can be:

    oss-process <file>:
        Processes the given file for OpenSim and outputs the result to
        standard output. If <file> is not given, read from standard input.
    rm <file> [<file>...]
        Deletes the given list of files.
""")

def rm(filelist):
    """Delete the given list of files, ignoring 'file not found' errors."""
    import os
    for i in filelist:
        try:
            os.unlink(i)
        except OSError as e:
            if e.errno != 2:
                raise
    return 0

def oss_process(filename):
    """Process a file for OpenSim Scripting."""
    import re

    # Regex that replaces a line with its OSS version when one's specified.
    os_line_re = re.compile(r'^( *).*?// ?OSS::(.*)$', re.MULTILINE)

    # Regex that removes lines between //LSL:: and //::LSL (can't begin on first line)
    sl_block_re = re.compile(r'\n\s*// ?LSL::(?:[^\n]|\n(?![ \t]*// ?::LSL[^\n]*?(?=\n)))*\n[ \t]*// ?::LSL[^\n]*(?=\n)')

    # Regex that removes /*OSS:: and its matching */ (can't begin on first line)
    os_block_re = re.compile(r'\n\s*/\* ?OSS::[^\n]*(\n(?:[^\n]|\n(?![ \t]*\*/))*)\n[ \t]*\*/[^\n]*(?=\n)')

    if filename is not None:
        f = open(filename, "r");
    else:
        f = sys.stdin
    try:
        s = f.read()
    finally:
        if filename is not None:
            f.close()

    # UUIDs in OpenSim
    s = s.replace('f2e0ed5e-6592-4199-901d-a659c324ca94',
                  '206fcbe2-47b3-41e8-98e6-8909595b8605')
    s = s.replace('b30c9262-9abf-4cd1-9476-adcf5723c029',
                  'b88526b7-3966-43fd-ae76-1e39881c86aa')
    # TODO: Replace LockGuard texture UUIDs

    # OpenSim 0.8.0 does not support this constant.
    #s = s.replace('OBJECT_BODY_SHAPE_TYPE', '26 /*OBJECT_BODY_SHAPE_TYPE*/')

    # Tag OpenSim releases
    s = s.replace('\n *\n * This Source Code', '\n * (OpenSim version)\n *\n * This Source Code')

    s = os_line_re.sub(r'\1\2', s)
    s = sl_block_re.sub('', s)
    s = os_block_re.sub(r'\1', s)
    sys.stdout.write(s)
    return 0

def main(argc, argv):
    if argc < 2:
        usage()
        return 0

    cmd = argv[1]
    if cmd == 'rm':
        return rm(argv[2:])

    if cmd == 'oss-process':
        if argc > 3:
            usage()
            return 1
        filename = argv[2] if argc == 3 else None
        return oss_process(filename)

    usage()
    return 1

ret = main(len(sys.argv), sys.argv)
if ret is not None and ret > 0:
    sys.exit(ret)
