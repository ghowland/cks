#!/bin/bash

./zig-out/bin/zig-tokenize.exe data/input.zig data/tokens.bin data/vocab.bin

./zig-out/bin/zig-train.exe data/tokens.bin data/vocab.bin data/weights.bin 50

./zig-out/bin/zig-infer.exe data/weights.bin data/vocab.bin "const std" 100

./zig-out/bin/zig-eval.exe data/weights.bin data/vocab.bin

