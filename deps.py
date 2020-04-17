#!/usr/bin/env python3

import os
import sys

__dir__ = os.path.dirname(os.path.realpath(__file__))


def read_deps(name):
    with open(os.path.join(__dir__, name + '.deps'), 'r', encoding='utf-8') as f:
        lines = f.read().split('\n')
        lines = [s.strip() for s in lines]
        return sorted([s for s in lines if len(s) > 0])


def filter(deps, exclude):
    return [d for d in deps if d not in exclude]

def dump(name):
    deps = read_deps(name)
    exclude = {
        'buildpack': [],
        'chrome': ['buildpack'],
        'tools': ['buildpack', 'chrome'],
    }
    prev = []
    for t in exclude[name]:
        prev = prev + read_deps(t)
    for d in filter(deps, set(prev)):
        print(f'  {d} \\')

def main():
    dump(sys.argv[1])

if __name__ == '__main__':
    main()
