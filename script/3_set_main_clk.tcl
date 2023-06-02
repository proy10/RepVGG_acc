set CLK_PERIOD  1

create_clock -period $CLK_PERIOD [get_ports clk]

set_input_delay 0.2 -clock clk [all_inputs]
set_output_delay 0.2 -clock clk [all_outputs]

set_clock_uncertainty -setup 0.1 clk
set_clock_uncertainty -hold  0.2 clk
set_clock_transition         0.2 clk

group_path -name in2reg -from [all_inputs]
group_path -name reg2out -to [all_outputs]
group_path -name in2out -from [all_inputs] -to [all_outputs]

