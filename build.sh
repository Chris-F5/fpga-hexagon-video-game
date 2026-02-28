#!/bin/bash

set -ex

# vga_wave
verilator --trace --cc src/vga.v --exe tb/vga_wave.cpp --prefix vga_wave --Mdir obj
make -j -C obj -f vga_wave.mk vga_wave

# hex_vga_display
verilator --cc src/hex_vga.v src/vga.v --exe tb/vga_display.cpp \
  --prefix vga_display --Mdir obj \
  -LDFLAGS "$(pkg-config --libs sdl2)" -CFLAGS "$(pkg-config --cflags sdl2)"
make -j -C obj -f vga_display.mk vga_display
