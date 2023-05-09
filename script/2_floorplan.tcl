#根据自己的设计确定摆放std cell和macro的core的大小以及core距离io的距离，后者受pin的数量以及power ring的布局
create_die_area  \
        -poly { {0.000 0.000} {1871.800 0.000} {1871.800 435.90} {0.000 435.90} }

#create_floorplan -control_type aspect_ratio -core_utilization 0.6 -start_first_row -flip_first_row -left_io2core 15 -bottom_io2core 15 -right_io2core 15 -top_io2core 15
create_floorplan -core_utilization 0.6 -left_io2core 30.0 -bottom_io2core 30.0 -right_io2core 30.0 -top_io2core 30.0

create_fp_virtual_pad -nets VSS -point {0 60}
create_fp_virtual_pad -nets VDD -point {0 20}


save_mw_cel -as 2_floorplan
		

