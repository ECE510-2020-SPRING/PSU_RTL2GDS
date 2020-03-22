
######
## WARNING!!!
## you must start innovus from the INNOVUS area and not the GENUS area
## /pkgs/cadence/2019-03/INNOVUS171/bin/innovus
## not /pkgs/cadence/2019-03/GENUS171/bin/innovus
##
## You need this as well in your .profile to get your libraries loaded correctly
## LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/pkgs/cadence/2019-03/SSV171/tools.lnx86/lib/64bit/"
## You might see this error otherwise.
## **ERROR: (IMPCCOPT-3092):	Couldn't load external LP solver library. Error returned:


source -echo -verbose ../../$top_design.design_config.tcl

set designs [get_db designs * ]
if { $designs != "" } {
  delete_obj $designs
}

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default

source ../scripts/innovus-get-timlibslefs.tcl

# need to create something more complicated for different link_library for each corner.
echo create_library_set -name libs_max -timing \"$link_library\" > mmmc.tcl
#create_op_cond
echo create_rc_corner -name cmax -T -40 -cap_table ../../cadence_cap_tech/saed32nm_1p9m_Cmax.cap >> mmmc.tcl
echo create_rc_corner -name cmin -T -40 -cap_table ../../cadence_cap_tech/saed32nm_1p9m_Cmin.cap >> mmmc.tcl
echo create_rc_corner -name default_rc_corner -T -40 -cap_table ../../cadence_cap_tech/saed32nm_1p9m_Cmax.cap >> mmmc.tcl
echo create_delay_corner -name max_corner -library_set libs_max -rc_corner cmax >> mmmc.tcl
echo create_delay_corner -name min_corner -library_set libs_max -rc_corner cmin >> mmmc.tcl
echo create_constraint_mode -name func_max_sdc -sdc_files ../../constraints/${top_design}.sdc >> mmmc.tcl
echo create_constraint_mode -name func_min_sdc -sdc_files ../../constraints/${top_design}.sdc >> mmmc.tcl
echo create_analysis_view -name func_max -delay_corner max_corner -constraint_mode func_max_sdc >> mmmc.tcl
echo create_analysis_view -name func_min -delay_corner min_corner -constraint_mode func_min_sdc >> mmmc.tcl
echo set_analysis_view -setup func_max -hold func_min >> mmmc.tcl

set init_design_netlisttype Verilog
set init_verilog ../../syn/outputs/${top_design}.genus_phys.vg
set init_top_cell $top_design
set init_pwr_net VDD
set init_gnd_net VSS
set init_mmmc_file mmmc.tcl

# Currently copy all the lef files from original locations and delete the BUSBITCHARS lines.  The "_" of  "_<>" is a problem.
foreach i $lef_path {
   exec grep -v BUSBITCHARS $i > [file tail $i ]
}
set init_lef_file "../../cadence_cap_tech/tech.lef [glob saed*.lef]"

init_design

set_interactive_constraint_modes [all_constraint_modes -active]

#setPreference EnableRectilinearDesign 1
#floorPlan -s 1000 400 0 0 0 0 -flip s -site unit
#setObjFPlanPolygon Cell $top_design {0 0 0 300 500 300 500 400 1000 400 1000 0}
#createRow -area "0 0 1000 300" -site unit
#createRow -area "500 300 1000 400" -site unit 

# if no IOs
#floorPlan -s [lindex $design_size 0 ] [lindex $design_size 1 ] $design_io_border $design_io_border $design_io_border $design_io_border -flip s -coreMarginsBy die
# If IOs
floorPlan -s [lindex $design_size 0 ] [lindex $design_size 1 ] 10 10 10 10 -flip s -coreMarginsBy io

#createRow -area "0.0000 0.0000 [lindex $design_size 0 ] [ lindex $design_size 1 ]" -site unit 

#placeInstance fifomem/genblk1_0__U 500 500 W -fixed

if { $add_ios } {
    source ../scripts/innovus-iofile.tcl
    loadIoFile ${top_design}.io
} else {
    setPinAssignMode -pinEditInBatch true
    # Change to the same layers as the bond pad and space apart by pad distance.
    editPin -edge 0 -pin [get_attribute [ get_ports -of_obj [ get_nets -of_obj [ get_pins io_l*/PADIO ] ] ] full_name ] -layer MRDL -spreadDirection clockwise -spreadType START -offsetStart 320 -spacing 40 -unit MICRON -fixedPin 0 
    editPin -edge 1 -pin [get_attribute [ get_ports -of_obj [ get_nets -of_obj [ get_pins io_t*/PADIO ] ] ] full_name ] -layer MRDL -spreadDirection clockwise -spreadType START -offsetStart 320 -spacing 40 -unit MICRON -fixedPin 0
    editPin -edge 2 -pin [get_attribute [ get_ports -of_obj [ get_nets -of_obj [ get_pins io_r*/PADIO ] ] ] full_name ] -layer MRDL -spreadDirection clockwise -spreadType START -offsetStart 320 -spacing 40 -unit MICRON -fixedPin 0
    editPin -edge 3 -pin [get_attribute [ get_ports -of_obj [ get_nets -of_obj [ get_pins io_b*/PADIO ] ] ] full_name ] -layer MRDL -spreadDirection clockwise -spreadType START -offsetStart 320 -spacing 40 -unit MICRON -fixedPin 0
    setPinAssignMode -pinEditInBatch false
}

# place the IO cells only
#placeAIO -onlyAIO
#place IO cells and others including macros
placeAIO 

#loadFPlan
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *

checkDesign -powerGround -noHtml -outfile pg.rpt

#######
# Make sure you place the macros before starting the power mesh.  Or maybe remove the -onlyAIO option of the placeAIO -onlyAIO
######

# Power Grid here.  This is ICC2 version:
# M7/8 Mesh
#create_pg_mesh_pattern mesh_pat -layers {  {{vertical_layer: M8} {width: 4} {spacing: interleaving} {pitch: 16}}   \
#    {{horizontal_layer: M7} {width: 2}        {spacing: interleaving} {pitch: 8}}  }
#M2 Lower Mesh
# Orca does 0.350 width VSS two stripes, then 0.7u VDD stripe.  Repeating 16u. for now, do something simpler 
#create_pg_mesh_pattern lmesh_pat -layers {  {{vertical_layer: M2} {width: 0.7} {spacing: interleaving} {pitch: 16}}  } 
#M1 Std Cell grid
#create_pg_std_cell_conn_pattern rail_pat -layers {M1} -rail_width {0.06 0.06}
#   -via_rule {       {{layers: M6} {layers: M7} {via_master: default}}        {{layers: M8} {layers: M7} {via_master: VIA78_3x3}}}
#set_pg_strategy mesh_strat -core -extension {{stop:outermost_ring}} -pattern {{pattern:mesh_pat } { nets:{VDD VSS} } } 
#set_pg_strategy rail_strat -core -pattern {{pattern:rail_pat } { nets:{VDD VSS} } } 
#set_pg_strategy lmesh_strat -core -pattern {{pattern:lmesh_pat } { nets:{VDD VSS} } } 
#compile_pg -strategies {mesh_strat rail_strat lmesh_strat}

# Core power ring
addRing -type core_rings -nets {VDD VSS} -layer {top METAL7 bottom METAL7 left METAL8 right METAL8} -offset 1 -width 8 -spacing 1.0 
# Add Meshes
#addStripe -nets {VDD VSS} -direction vertical   -layer M2 -width 0.5 -set_to_set_distance 16 -xleft_offset 2.75 -spacing 5
#addStripe -nets {VDD VSS} -direction horizontal   -layer M3 -width 0.5 -set_to_set_distance 16 -ybottom_offset 2.75 -spacing 5
addStripe -nets {VDD VSS} -direction vertical   -layer M4 -width 4 -set_to_set_distance 16 -xleft_offset  1 -spacing 1
addStripe -nets {VDD VSS} -direction horizontal -layer M7 -width 4 -set_to_set_distance 16 -ybottom_offset 1 -spacing 1
addStripe -nets {VDD VSS} -direction vertical   -layer M8 -width 4 -set_to_set_distance 16 -xleft_offset  1 -spacing 1
sroute -connect corePin
sroute -connect padPin

#return -level 9

# Add dcap boundary cells on the left and right side of design and macros
#set_boundary_cell_rules -left_boundary_cell [get_lib_cell */DCAP_HVT]
#set_boundary_cell_rules -right_boundary_cell [get_lib_cell */DCAP_HVT]
# Tap Cells are usually needed, but they are not in this library. create_tap_cells
#compile_boundary_cells

#loadDefFile ../../apr/outputs/${top_design}.floorplan.def

#set_interactive_constraint_modes [all_constraint_modes -active]
#source ../../constraints/$top_design.sdc

setDontUse *DELLN* true

createBasicPathGroups -expanded

place_opt_design

ccopt_design

setAnalysisMode -analysisType onChipVariation
setAnalysisMode -cppr both

optDesign -postCTS -hold
#opt_design -post_cts -hold

routeDesign
#route_design

optDesign -postRoute -setup -hold
#opt_design -post_route -setup -hold

saveDesign ${top_design}_route

# output reports
set stage route
timeDesign -postRoute -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews
timeDesign -postRoute -si -prefix ${stage}_si -outDir ../reports/${top_design}.innovus -expandedViews
timeDesign -postRoute -hold -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews
timeDesign -postRoute -hold -si -prefix ${stage}_si -outDir ../reports/${top_design}.innovus -expandedViews

# output netlist.  Look in the Saved Design Directory for the netlist
#write_hdl $top_design > ../outputs/${top_design}.$stage.vg

