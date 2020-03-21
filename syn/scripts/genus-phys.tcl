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

# Load the tech lef and cell lef files
set_db lef_library "../../cadence_cap_tech/tech.lef $lef_path"

# Do we need this?
#license checkout Genus_Physical_Opt

# We can make the cap table from the Synopsys Library information, but I have not found how to make the qrc_tech_file
#set_db qrc_tech_file $QRC_TECH_FILE_NAME
set_db cap_table_file $topdir/cadence_cap_tech/saed32nm_1p9m_Cmax.cap


# Analyzing the current FIFO design
read_hdl -language sv ../rtl/${top_design}.sv

set_db hdl_array_naming_style %s_%d
set_db hdl_instance_array_naming_style %s_%d
set_db bus_naming_style %s_%d
set_db hdl_record_naming_style %s_%s
set_db hdl_parameter_naming_style _%s%d
#set_db hdlin_template_naming_style "%s_%p"
#set_db hdlin_template_parameter_style "%d"
#set_db hdlin_template_separator_style "_"
#set_db hdlin_template_parameter_style_variable "%d" 

# Elaborate the FIFO design
elaborate $top_design

update_names -map { {"." "_" }} -inst -force
update_names -map {{"[" "_"} {"]" "_"}} -inst -force
update_names -map {{"[" "_"} {"]" "_"}} -port_bus
update_names -map {{"[" "_"} {"]" "_"}} -hport_bus
update_names -inst -hnet -restricted {[} -convert_string "_"
update_names -inst -hnet -restricted {]} -convert_string "_"

# Load the timing and design constraints
source -echo -verbose ../../constraints/${top_design}.sdc

read_def ../../apr/outputs/${top_design}.floorplan.def

syn_generic -physical

# any additional non-design specific constraints
#set_max_transition 0.5 [current_design ]

# Duplicate any non-unique modules so details can be different inside for synthesis
uniquify $top_design

#compile with ultra features and with scan FFs
syn_map -physical
syn_opt

# output reports
set stage genus_phys
report_qor > ../reports/${top_design}.$stage.qor.rpt
#report_constraint -all_viol > ../reports/${top_design}.$stage.constraint.rpt
report_timing -max_path 1000 > ../reports/${top_design}.$stage.timing.max.rpt
check_timing_intent -verbose  > ../reports/${top_design}.$stage.check_timing.rpt
check_design  > ../reports/${top_design}.$stage.check_design.rpt
#check_mv_design  > ../reports/${top_design}.$stage.mvrc.rpt

# output netlist
write_hdl $top_design > ../outputs/${top_design}.$stage.vg
