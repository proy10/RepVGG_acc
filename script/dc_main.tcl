set_host_options -max_cores 4

source ../script/1_setup.tcl

source ../script/2_read_file.tcl 

current_design $top

#link
check_design 

source ../script/3_set_main_clk.tcl

source ../script/4_set_mode_inout_drc_load.tcl

#compile > ../log/compile.log 
compile

source ../script/5_write_file.tcl

