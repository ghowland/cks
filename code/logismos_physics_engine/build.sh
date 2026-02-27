#!/bin/bash

ZIG=/mnt/c/zig/zig-x86_64-windows-0.15.1/zig.exe

reset ; $ZIG build -freference-trace --prefix build/ && \
  ./build/bin/logismos.exe $1
