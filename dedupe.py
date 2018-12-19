#!/usr/bin/env python3

import fileinput

proc = {}

for line in fileinput.input():
    line = line.strip()
    if len(line) == 0:
        print(line)
        continue
    if line.startswith("#"):
        print(line)
        continue
    if line in proc:
        continue
    print(line)
    proc[line] = 1
