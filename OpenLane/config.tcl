set ::env(DESIGN_NAME) async_fifo

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) "wr_clk"
set ::env(CLOCK_PERIOD) "20"

set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.45

set ::env(RUN_CTS) 1
set ::env(RUN_MAGIC_DRC) 1
set ::env(RUN_LVS) 1

# Custom timing constraints for both clock domains.
set ::env(BASE_SDC_FILE) "$::env(DESIGN_DIR)/timing/constraints.sdc"

# Additional antenna protection
set ::env(GRT_REPAIR_ANTENNAS) 1
set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1
set ::env(HEURISTIC_ANTENNA_THRESHOLD) 90
