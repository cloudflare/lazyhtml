#!/usr/bin/env python
import xml.etree.cElementTree as ET
import re

failure_re = re.compile(r"""thread '(.*?)' panicked at '(.*?)', tests/test\.rs:\d+:\d+
(?:note: Run with `RUST_BACKTRACE=1` for a backtrace.
)?failed \1\n""", re.DOTALL)

success_re = re.compile("(ok|ignored) (.*?)\n")

log = open('test.log', 'r').read()

root = ET.Element('testsuite', name='html5lib-tests')

pos = 0
while pos < len(log):
    match = success_re.match(log, pos)
    if match is not None:
        status, name = match.groups()
        case = ET.SubElement(root, 'testcase', name=name)
        if status == 'ignored':
            ET.SubElement(case, 'skipped')
    else:
        match = failure_re.match(log, pos)
        assert match is not None, "Could not parse %r" % log[pos:].split('\n', 1)[0]
        name, msg = match.groups()
        case = ET.SubElement(root, 'testcase', name=name)
        ET.SubElement(case, 'failure').text = msg
    pos = match.end()

ET.ElementTree(root).write('test.xml')
