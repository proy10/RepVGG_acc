current_design $top

set all_in_ex_rstn [remove_from_collection [all_inputs] [get_ports rst_n]]
set all_in_ex_clk_rstn [remove_from_collection $all_in_ex_rstn [get_ports clk]]

set_wire_load_model -name "16000" -library saed32rvt_ss0p95v125c

set_driving_cell -lib_cell INVX1_RVT -library saed32rvt_ss0p95v125c $all_in_ex_clk_rstn

set_fanout_load 2 [all_outputs]

                                                              
