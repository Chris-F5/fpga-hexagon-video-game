#!/bin/bash

set -ex

# dividor_s_16_16
verilator --trace --cc src/dividor_s_16_16.v --exe tb/dividor_s_16_16_tb.cpp --prefix dividor_s_16_16_tb --Mdir obj
make -j -C obj -f dividor_s_16_16_tb.mk dividor_s_16_16_tb

# projection
verilator --trace --cc src/projection.v src/dividor_s_16_16.v --exe tb/projection_tb.cpp --prefix projection_tb --Mdir obj
make -j -C obj -f projection_tb.mk projection_tb

# vga_wave
verilator --trace --cc src/vga.v --exe tb/vga_wave.cpp --prefix vga_wave --Mdir obj
make -j -C obj -f vga_wave.mk vga_wave

# hex_vga_display
verilator --cc src/hex_vga.v src/projection.v src/dividor_s_16_16.v src/hex_plane.v src/vga.v --exe tb/vga_display.cpp \
  --prefix vga_display --Mdir obj \
  -LDFLAGS "$(pkg-config --libs sdl2)" -CFLAGS "$(pkg-config --cflags sdl2)"
make -j -C obj -f vga_display.mk vga_display
