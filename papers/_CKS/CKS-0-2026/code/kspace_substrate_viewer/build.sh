#!/bin/bash -e

# Assumes WSL2 on Windows

# # Clear the cache every time
# rm -rf .zig-cache/

ZIG=/mnt/c/zig/zig-x86_64-windows-0.15.1/zig.exe

reset ; $ZIG build -Doptimize=Debug -freference-trace --prefix build/


