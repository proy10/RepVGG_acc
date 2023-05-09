#set_fp_pin_constraints -block_level -use_physical_constraints on -hard_constraints {layer location}
#set_ignored_layers -max_routing_layer M8

set_ignored_layers -max_routing_layer M8
create_fp_placement -timing_driven -no_hierarchy_gravity

#Fix the SRAM Macros
#create_placement_blockage -bbox {266.718 520.381 734.888 733.976}
#create_placement_blockage -bbox {30.000 30.000 285.690 452.000}
#set_dont_touch_placement [all_macro_cells]

source ../scripts/derive_pg.tcl


#create_fp_placement -timing -no_hier -optimize_pins
#derive_pg_connection -power_net VDD -power_pin VDD -ground_net GND -ground_pin GND
#derive_pg_connection -power_net VDDH -power_pin VDDH -ground_net VSSH -ground_pin VSSH
#derive_pg_connection -power_net VDD -ground_net GND -tie
check_mv_design -power_nets

route_global -congestion_map_only
check_timing
save_mw_cel -as 3_pre_pns
