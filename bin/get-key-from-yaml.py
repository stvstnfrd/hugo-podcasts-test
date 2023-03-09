#!/usr/bin/env python3
import sys

import yaml


def main():
    filename = sys.argv[1]
    path = sys.argv[2]
    data = None
    with open(filename, 'r', encoding='utf-8') as _file:
        data = yaml.load(_file, Loader=yaml.Loader)
    paths = path.split('.')
    for path in paths:
        data = data.get(path)
        if not data:
            break
    return data


if __name__ == '__main__':
    print(main())
