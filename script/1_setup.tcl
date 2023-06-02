set top "acc_top"
set std_path "/home/riscv/library/dc"

set search_path [list $std_path/ ]

set     target_library          "saed32rvt_ss0p95v125c.db sram_8kx32_ss_0p99v_0p99v_125c.db sram_4kx64_ss_0p99v_0p99v_125c.db"
set     link_library            "* $target_library"

define_name_rules BORG -type net -allowed "A-Z a-z 0-9" -first_restricted "_0-9\\" \
        -last_restricted "_0-9\\" -max_length 30


