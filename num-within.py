#!/usr/bin/env python3
import sys

num_from  = int(sys.argv[1])
num_until = int(sys.argv[2])

for line in sys.stdin:
    n = int(line)
    if num_from <= n < num_until:
        print(str(n))
