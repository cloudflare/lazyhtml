#!/usr/bin/env python
import xml.etree.cElementTree as ET
import re

failure_re = re.compile(r"""thread '(.*?)' panicked at '(.*?)', tests/test\.rs:\d+:\d+
(?:note: Run with `RUST_BACKTRACE=1` for a backtrace.
)?""", re.DOTALL)

tests = open('tests.log', 'r').read().rstrip().split('\n')
failures = open('failures.log', 'r').read()
failures_pos = 0

root = ET.Element('testsuite', name='html5lib-tests', tests=str(len(tests)))

for test in tests:
    (status, name) = test.split(' ', 1)
    case = ET.SubElement(root, 'testcase', name=name)
    if status == 'failed':
        match = failure_re.match(failures, failures_pos)
        assert match is not None, "Could not parse %r" % failures[failures_pos:].split('\n', 1)[0]
        failure_name, details = match.groups()
        assert name == failure_name, "Could not find failure message for %s" % name
        ET.SubElement(case, 'failure').text = details
        failures_pos = match.end()
    elif status == 'ignored':
        ET.SubElement(case, 'skipped')
    else:
        assert status == 'ok', 'Unknown test status: %s' % status

ET.ElementTree(root).write('tests.xml')
