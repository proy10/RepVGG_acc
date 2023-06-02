write -hierarchy -format verilog -output ../mapped/$top.mapped.v

write_sdf ../mapped/$top.sdf

write_sdc -version 1.9 ../mapped/$top.sdc

report_area -hierarchy > ../rpts/$top.area.rpts

report_power > ../rpts/$top.power.rpts

report_constrain -all_violators > ../rpts/$top.violators.rpts

report_net_fanout >  ../rpts/$top.net_fanout.rpts

report_timing > ../rpts/$top.timing.rpts

