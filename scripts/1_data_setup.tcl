set_host_options -max_cores 4

#修改成你的库文件的绝对路径
set std_path "/home/riscv/library/icc/db"
set tech_file_path "/home/riscv/library/icc/tf"
set tlu_plus_file_path "/home/riscv/library/icc/tluplus"

set search_path [list $std_path \
                      $tech_file_path \
		      $tlu_plus_file_path ]

#修改路径
set verilog_file "../design_data/acc_top.mapped.v"
set sdc_file "../design_data/acc_top.sdc"


#target library-----------------------------------------------------------
set     target_library          saed32rvt_ff1p16vn40c.db
set     mem_lib1                sram_4kx64_ss_0p99v_0p99v_125c.db
set     mem_lib2                sram_8kx32_ss_0p99v_0p99v_125c.db

set     link_library            [list  "*" $target_library $mem_lib2]

#create library
create_mw_lib  -technology $tech_file_path/saed32nm_1p9m_mw.tf              \
               -mw_reference_library {/home/riscv/library/icc/mw_lib/saed32nm_rvt_1p9m \
                                      /home/riscv/library/icc/mw_lib/sram_4kx64    \
			              /home/riscv/library/icc/mw_lib/sram_8kx32    }   \
               -hier_separator {/} \
               -bus_naming_style {[%d]} \
               -open ../conv.mw

set_check_library_options -all

#set TLU+ files
set_tlu_plus_files   -max_tluplus   $tlu_plus_file_path/saed32nm_1p9m_Cmax.tluplus     \
                     -min_tluplus   $tlu_plus_file_path/saed32nm_1p9m_Cmin.tluplus     \
                     -tech2itf_map  $tlu_plus_file_path/saed32nm_tf_itf_tluplus.map

check_tlu_plus_files

#import designs
import_designs -format verilog $verilog_file

#derive_pg_connection -power_net VDD -power_pin VDD -ground_net GND -ground_pin GND
#derive_pg_connection -power_net VDDH -power_pin VDDH -ground_net VSSH -ground_pin VSSH
#derive_pg_connection -power_net VDD -ground_net GND -tie

source ../scripts/derive_pg.tcl

read_sdc $sdc_file

list_libs
check_timing
report_timing_requirements
report_disable_timing
report_case_analysis
report_clock -skew

#source ../scripts/opt_ctrl.tcl
#group_path -name reg2out -from [all_registers -clock_pins] -to [all_outputs]
#group_path -name in2reg -from [remove_from_collection [all_inputs] $ports_clock_root] -to [all_registers -data_pins]
#group_path -name in2out -from [remove_from_collection [all_inputs] $ports_clock_root] -to [all_outputs]

save_mw_cel -as 1_data_setup
