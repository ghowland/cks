#!/bin/bash -e

ZIG=/mnt/c/zig/zig-x86_64-windows-0.15.1/zig.exe

# Build and Run
reset ; $ZIG build -freference-trace --prefix build/ && \
  ./build/bin/vfr_llm.exe $1

