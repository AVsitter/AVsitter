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

    setvars <file> <var>=<value> ...:
        Preprocesses the given file in place, to replace values like
        version and others.
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

    # Regex that reads a token, can be a string or comment or #IDENT or anything else,
    # capturing a group for IDENT when #IDENT is found.
    token_re = re.compile(r'"(?:\\.|[^"\\]+)*"|/\*[\S\s]*?\*/|//[^\n]*|/|[^#/"]+|#([a-zA-Z_][a-zA-Z0-9_]*)|#')

    if filename is not None:
        f = open(filename, "r")
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

    # OpenSim 0.8.0 does not support this constant.
    #s = s.replace('OBJECT_BODY_SHAPE_TYPE', '26 /*OBJECT_BODY_SHAPE_TYPE*/')

    # Tag OpenSim releases
    s = s.replace('\n *\n * This Source Code', '\n * (OpenSim version)\n *\n * This Source Code')

    s = os_line_re.sub(r'\1\2', s)
    s = sl_block_re.sub('', s)
    s = os_block_re.sub(r'\1', s)

    new = ''
    for match in token_re.finditer(s):
        if match.group(1):
            new += match.group(1)  # remove '#'
        else:
            new += match.group(0)
    s = new

    sys.stdout.write(s)
    return 0

def setvars(filename, *settings):
    """Preprocess a file in place, to replace values"""
    import re

    values = {}
    var_value_re = re.compile(r'^([^=]*)=(.*)$')
    for v in settings:
        match = var_value_re.search(v)
        if not match:
            sys.stderr.write('Incorrect setting format, it should be key=value\n')
            return 1
        values[match.group(1)] = match.group(2)

    if filename is not None:
        f = open(filename, "r")
    else:
        f = sys.stdin
    try:
        s = f.read()
    finally:
        if filename is not None:
            f.close()

    orig = s
    # Regex to read a token in the set of expected tokens.
    # NOTE: This regex deliberately ignores // so that //#variable = value; is still valid.
    token_re = re.compile(r'"(?:\\.|[^"\\]+)*"|/\*[\S\s]*?\*/|/|;|[^#;/"]+|#([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*|#')
    p = 0
    while True:
        match = token_re.search(s, p)
        if not match:
            break
        if match.group(1) in values:
            # found '#variable = ' in the code, and variable matches
            value = values[match.group(1)]
            # mark the start of the value as the end of the match
            vbegin = match.end(0)
            while True:
                # keep skipping tokens until we hit a ';'
                p = match.end(0)
                match = token_re.search(s, p)
                if not match:
                    # end of script? this is wrong but better don't crash
                    vend = vbegin
                    break
                if match.group(0) == ';':
                    # mark end of value before the matching ';'
                    vend = match.start(0)
                    break
            # Replace the value between vbegin and vend
            s = s[:vbegin] + value + s[vend:]
            # Advance past the value to keep searching
            p = vbegin + len(value)
            continue
        # not a token we're interested in - keep searching after it
        p = match.end(0)

    if s != orig:
        if filename is not None:
            f = open(filename, "w")
        else:
            f = sys.stdout
        try:
            f.write(s)
        finally:
            if filename is not None:
                f.close()

def main(argc, argv):
    if argc < 2:
        usage()
        return 0

    cmd = argv[1]
    if cmd == 'rm':
        return rm(argv[2:])

    if cmd == 'setvars':
        filename = None if argv[2] == '-' else argv[2]
        return setvars(filename, *argv[3:])

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
