history keep 100
set_db timing_report_fields "delay arrival transition fanout load cell timing_point"

set designs [get_db designs * ]
if { $designs != "" } {
  delete_obj $designs
}

# Set up the search path to the libraries
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_hvt/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_rvt/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_lvt/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/io_std/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/sram/db_nldm"

set_db init_lib_search_path $search_path

# Indicate where the foundation synthesis library is
set synthetic_library dw_foundation.sldb

# Indicate what library gates to synthesize RTL logic 
set target_library "saed32lvt_ss0p75v125c.lib saed32rvt_ss0p75v125c.lib"

# Indicate what libraries to link to including the target_library and others.
# Removed the synthetic library and * and hvt
set link_library [join "$target_library saed32io_wb_ss0p95v125c_2p25v.lib saed32sram_ss0p95v125c.lib" ]

set_db library $link_library

# Analyzing the current FIFO design
read_hdl -language sv ../rtl/${top_design}.sv

# Elaborate the FIFO design
elaborate $top_design

syn_generic

# Load the timing and design constraints
source -echo -verbose ../../constraints/${top_design}.sdc

# any additional non-design specific constraints
#set_max_transition 0.5 [current_design ]

# Duplicate any non-unique modules so details can be different inside for synthesis
uniquify $top_design

#compile with ultra features and with scan FFs
syn_map
syn_opt

# output reports
set stage genus
report_qor > ../reports/${top_design}.$stage.qor.rpt
#report_constraint -all_viol > ../reports/${top_design}.$stage.constraint.rpt
report_timing -max_path 1000 > ../reports/${top_design}.$stage.timing.max.rpt
check_timing_intent -verbose  > ../reports/${top_design}.$stage.check_timing.rpt
check_design  > ../reports/${top_design}.$stage.check_design.rpt
#check_mv_design  > ../reports/${top_design}.$stage.mvrc.rpt

# output netlist
write_hdl $top_design > ../outputs/${top_design}.$stage.vg

