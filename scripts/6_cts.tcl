check_clock_tree

set_max_fanout 20 [current_design]
set_max_transition 0.15 [current_design]
set_host_options -max_cores 4
set_route_mode_options -zroute true
#set_delay_calculation -clock_arnoldi
set_delay_calculation_options -routed_clock arnoldi -postroute arnoldi
set_clock_tree_references -references {IBUFFX2_RVT IBUFFX4_RVT IBUFFX8_RVT IBUFFX16_RVT IBUFFX32_RVT}
set_clock_tree_references -references {IBUFFX8_RVT IBUFFX16_RVT}  -sizing_only
set_clock_tree_references -references {IBUFFX2_RVT IBUFFX4_RVT}  -delay_insertion_only

#remove_clock_uncertainty [all_clocks]
set_clock_uncertainty 0.1 [all_clocks]
clock_opt -no_clock_route -only_cts
set_fix_hold [all_clocks]
extract_rc
clock_opt -no_clock_route -only_psyn -area_recovery
optimize_clock_tree
set_propagated_clock [all_clocks]
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -tie

save_mw_cel -as 6_cts

