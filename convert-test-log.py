#!/usr/bin/env python
import xml.etree.cElementTree as ET

lines = open('test.log', 'r').read().rstrip().split('\n')

root = ET.Element('testsuite', name='html5lib-tests', tests=str(len(lines)))

for line in lines:
    (status, name) = line.split(' ', 1)
    case = ET.SubElement(root, 'testcase', name=name)
    if status == 'failed':
        ET.SubElement(case, 'failure')
    elif status == 'ignored':
        ET.SubElement(case, 'skipped')
    else:
        assert status == 'ok', 'Unknown test status: %s' % status

ET.ElementTree(root).write('test.xml')
