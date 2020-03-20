
source -echo -verbose ../../$top_design.design_config.tcl

set designs [get_db designs * ]
if { $designs != "" } {
  delete_obj $designs
}

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default

source ../scripts/innovus-get-timlibslefs.tcl

set init_design_netlisttype Verilog
set init_verilog ../../syn/outputs/${top_design}.genus_phys.vg
set init_top_cell $top_design
set init_pwr_net VDD
set init_gnd_net VSS
# Currently copy all the lef files from original locations and delete the BUSBITCHARS lines.  The "_" of  "_<>" is a problem.
set init_lef_file "../../cadence_cap_tech/tech.lef [glob *.lef]"
#set init_mmmc_file viewDefinition.tcl

init_design

# need to create something more complicated for different link_library for each corner.
create_library_set -name libs_max -timing $link_library
create_rc_corner -name cmax -T -40 -cap_table ../../cadence_cap_tech/saed32nm_1p9m_Cmax.cap
create_constraint_mode -name func_max_sdc -sdc_files ../../constraints/${top_design}.sdc
create_delay_corner -name max_corner -library_set libs_max -rc_corner cmax
create_analysis_view -name func_max -delay_corner max_corner -constraint_mode func_max_sdc


#setPreference EnableRectilinearDesign 1
#floorPlan -s 1000 400 0 0 0 0 -flip s -site unit
#setObjFPlanPolygon Cell $top_design {0 0 0 300 500 300 500 400 1000 400 1000 0}
#createRow -area "0 0 1000 300" -site unit
#createRow -area "500 300 1000 400" -site unit 

floorPlan -s [lindex $design_size 0 ] [lindex $design_size 1 ] $design_io_border $design_io_border $design_io_border $design_io_border -flip s 
#createRow -area "0.0000 0.0000 [lindex $design_size 0 ] [ lindex $design_size 1 ]" -site unit 

#placeInstance fifomem/genblk1_0__U 500 500 W -fixed

setPinAssignMode -pinEditInBatch true
editPin -edge 0 -pin [get_attribute [ get_ports wdata* ] full_name ] -layer 5 -spreadDirection clockwise -spreadType START -offsetStart 80 -fixedPin 1
editPin -edge 1 -pin [get_attribute [ get_ports {rclk rrst_n rinc rempty} ] full_name ] -layer 5 -spreadDirection clockwise -spreadType START -offsetStart 80 -fixedPin 1
editPin -edge 2 -pin [get_attribute [ get_ports rdata* ] full_name ] -layer 5 -spreadDirection clockwise -spreadType START -offsetStart 80 -fixedPin 1
editPin -edge 3 -pin [get_attribute [ get_ports {wclk wclk2x wrst_n winc wfull} ] full_name ] -layer 5 -spreadDirection clockwise -spreadType START -offsetStart 80 -fixedPin 1
setPinAssignMode -pinEditInBatch false


#loadFPlan
#globalNetConnect

#loadDefFile ../../apr/outputs/${top_design}.floorplan.def

set_interactive_constraint_modes [all_constraint_modes -active]
source ../../constraints/$top_design.sdc

place_opt_design
ccopt_design
opt_design -post_cts -hold
route_design
opt_design -post_route -setup -hold


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

