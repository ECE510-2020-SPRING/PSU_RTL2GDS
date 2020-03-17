source -echo -verbose ../../$top_design.design_config.tcl

if { ![ info exists dc_floorplanning ] } {
   set dc_floorplanning 1
}

# Source common setup file
set my_lib ${top_design}_fp_lib
source -echo -verbose ../scripts/setup2.tcl
source -echo -verbose ../scripts/read2.tcl

# Source before floorplan in case we want to use timing to place pins
# Our time to load constraints is relatively small so we can do it at this spot if we want
source -echo -verbose -continue_on_error ../../constraints/${top_design}.sdc
initialize_floorplan -control_type core -shape R -side_length $design_size -core_offset $design_io_border


# FIXME
#foreach net {VDD} { derive_pg_connection -power_net $net -power_pin $net -create_ports top}
#foreach net {VSS} { derive_pg_connection -ground_net $net -ground_pin $net -create_ports top}

# Try this or another loop of code.
# This one will do the correct IO pads, but causes problems with the power routing for some reason.
# The other side will do the power routing correctly, but does not have the IO pads.
# Change things so that all the real IO Pads are put in for the design as needed and connect ports to pad connections.
# Maybe this will fix things?
# Need 15 inputs and 10 outputs
if { $pad_design } {
	source -echo -verbose ../scripts/floorplan-ios2.tcl

} 


#FIXME
#derive_pg_connection -tie
connect_pg_net -automatic

puts "Starting FP Placement: ..."
#FIXME
# Placement
remove_placement_blockages [get_placement_blockages * ]
#set_fp_placement_strategy -auto_grouping medium
set_app_option -name plan.macro.auto_macro_array_size -value high 
#set_fp_placement_strategy -macro_orientation automatic
#set_fp_placement_strategy -macros_on_edge on
set_app_option -name plan.macro.macros_on_edge -value true

#set_fp_placement_strategy -auto_grouping_max_columns 2
#set_app_options -name plan.macro.auto_macro_array_max_num_cols -value 2
set_app_options -name plan.macro.auto_macro_array_max_height -value 520u
#set_fp_placement_strategy -auto_grouping_max_rows 2
#set_app_options -name plan.macro.auto_macro_array_max_num_rows -value 2
set_app_options -name plan.macro.auto_macro_array_max_width -value 520u
#set_fp_placement_strategy -min_distance_between_macros 1
set_app_option -name plan.macro.spacing_rule_heights -value { 15um 15um }
set_app_option -name plan.macro.spacing_rule_widths -value { 15um 15um }
#set_fp_placement_strategy -sliver_size 50
set_app_options -name plan.macro.macro_place_only  -value true
#create_fp_placement -timing_driven -optimize_pins
set_app_options -name plan.macro.grouping_by_hierarchy -value true
set_app_options -name plan.macro.max_buffer_stack_height -value 0u
set_app_options -name plan.macro.max_buffer_stack_width -value 0u
set_app_options -name plan.macro.auto_buffer_channels -value false
set_app_options -name plan.macro.buffer_channel_height -value 0u
set_app_options -name plan.macro.buffer_channel_width -value 0u

# Source the floorplan design options here after we have set some decent defaults.
source -echo -verbose ../../${top_design}.design_options.tcl

place_pins -self
create_placement -floorplan

set_attribute -objects [get_cells -hier -filter "is_hard_macro==true" ] -name physical_status -value fixed

# Do this section again after you like your postion of macros.  
write_def -include {cells ports blockages } -cell_types {macro} "../outputs/${top_design}.floorplan.macros.def"

