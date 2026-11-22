# Asynchronous FIFO: initial physical-design constraints

create_clock -name wr_clk -period 20 [get_ports wr_clk]
create_clock -name rd_clk -period 20 [get_ports rd_clk]

# Constrain ordinary synchronous paths within each clock domain.
set_clock_uncertainty 0.5 [get_clocks {wr_clk rd_clk}]

# Asynchronous reset is not timed as a synchronous data input.
set_false_path -from [get_ports rst_n]

# Input timing
set_input_delay 2 -clock wr_clk [get_ports {wr_en wr_data*}]
set_input_delay 2 -clock rd_clk [get_ports rd_en]

# Output timing
set_output_delay 2 -clock wr_clk [get_ports wr_full]
set_output_delay 2 -clock rd_clk [get_ports {rd_data* rd_empty rd_valid}]

# CDC crossing paths need separate verification.
# Do not globally false-path both clock domains here.
