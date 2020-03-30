history keep 100
set_db timing_report_fields "delay arrival transition fanout load cell timing_point"

source -echo -verbose ../../$top_design.design_config.tcl

set designs [get_db designs * ]
if { $designs != "" } {
  delete_obj $designs
}

source ../scripts/genus-get-timlibslefs.tcl

set_db init_lib_search_path $search_path

set_db library $link_library

# Analyzing the current FIFO design
read_hdl -language sv ../rtl/${top_design}.sv

#set_db hdl_array_naming_style %s_%d
#set_db hdl_instance_array_naming_style %s_%d
#set_db bus_naming_style %s_%d
#set_db hdl_record_naming_style %s_%s
#set_db hdl_parameter_naming_style _%s%d
#set_db hdlin_template_naming_style "%s_%p"
#set_db hdlin_template_parameter_style "%d"
#set_db hdlin_template_separator_style "_"
#set_db hdlin_template_parameter_style_variable "%d" 

# Elaborate the FIFO design
elaborate $top_design

#return -level 9 

if { [ info exists add_ios ] && $add_ios } {
   source -echo -verbose ../scripts/genus-add_ios.tcl
   # Source the design dependent code that will put IOs on different sides
   source ../../$top_design.add_ios.tcl
}

# This needs to be after add_ios
update_names -map { {"." "_" }} -inst -force
update_names -map {{"[" "_"} {"]" "_"}} -inst -force
update_names -map {{"[" "_"} {"]" "_"}} -port_bus
update_names -map {{"[" "_"} {"]" "_"}} -hport_bus
update_names -inst -hnet -restricted {[} -convert_string "_"
update_names -inst -hnet -restricted {]} -convert_string "_"


# Load the timing and design constraints
source -echo -verbose ../../constraints/${top_design}.sdc

set_dont_use [get_lib_cells */DELLN* ]

syn_generic
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

