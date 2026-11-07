#!/bin/sh
cd "$(dirname "$0")"
mkdir -p build
iverilog -g2012 -o build/sim.vvp ../rtl/apb_slave.sv ../tb/apb_master.sv ../tb/top.sv || exit 1
vvp build/sim.vvp "$@"