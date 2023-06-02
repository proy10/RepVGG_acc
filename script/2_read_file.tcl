set rtl_dir ../rtl

analyze -format verilog [glob $rtl_dir/*.v]
elaborate $top

check_design
