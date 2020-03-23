
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

if { ! [ info exists flow ] } { set flow "fpcr" }

####### STARTING INITIALIZE and FLOORPLAN #################
if { [regexp -nocase "f" $flow ] } {
    puts "######## STARTING INITIALIZE and FLOORPLAN #################"

    set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default

    source ../scripts/innovus-get-timlibslefs.tcl
    source ../../constraints/${top_design}.mmmc.sdc

    set init_design_netlisttype Verilog
    set init_verilog ../../syn/outputs/${top_design}.genus_phys.vg
    set init_top_cell $top_design
    set init_pwr_net VDD
    set init_gnd_net VSS


    init_design

    defIn "../outputs/${top_design}.floorplan.innovus.def" 

    source ../../${top_design}.design_options.tcl

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

    saveDesign ${top_design}_floorplan.innovus
    puts "######## FINISHED INTIIALIZE and FLOORPLAN #################"
}

######## PLACE #################
if { [regexp -nocase "p" $flow ] } {
    if { ![regexp -nocase "f" $flow ] } {
       restoreDesign ${top_design}_floorplan.innovus.dat ${top_design}
    }
    puts "######## STARTING PLACE #################"


    place_opt_design

    set stage place
    timeDesign -preCTS -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews
    saveDesign ${top_design}_place.innovus

    puts "######## FINISHED PLACE #################"
}

######## STARTING CLOCK_OPT #################
if { [regexp -nocase "c" $flow ] } {
    if { ![regexp -nocase "f" $flow ] && ![regexp -nocase "p" $flow ]  } {
       restoreDesign ${top_design}_place.innovus.dat ${top_design}
    } elseif { [regexp -nocase "f" $flow ] && ![regexp -nocase "p" $flow ] } {
       puts "FLOW ERROR: You are trying to run route and skipping some but not all earlier stages"
       return -level 1 
    }

    ccopt_design
    setAnalysisMode -analysisType onChipVariation
    setAnalysisMode -cppr both

    optDesign -postCTS -hold
    #opt_design -post_cts -hold

    set stage postcts
    timeDesign -postCTS -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews
    timeDesign -postCTS -hold -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews

    saveDesign ${top_design}_postcts.innovus
    puts "######## FINISHING CLOCK_OPT #################"

}

######## ROUTE_OPT #################
if { [regexp -nocase "r" $flow ] } {
    if { ![regexp -nocase "f" $flow ] && ![regexp -nocase "p" $flow ] && ![regexp -nocase "c" $flow ] } {
       restoreDesign ${top_design}_postcts.innovus.dat ${top_design}
    } elseif { ([regexp -nocase "f" $flow ] && ! [regexp -nocase "p" $flow ] ) ||
               ([regexp -nocase "f" $flow ] && ! [regexp -nocase "c" $flow ] ) ||
               ([regexp -nocase "p" $flow ] && ! [regexp -nocase "c" $flow ] )  } {
       puts "FLOW ERROR: You are trying to run route and skipping some but not all earlier stages"
       return -level 1 
    }
    puts "######## ROUTE_OPT #################"

    routeDesign
    #route_design

    optDesign -postRoute -setup -hold
    #opt_design -post_route -setup -hold

    saveDesign ${top_design}_route.innovus

    ######## FINAL REPORTS/OUTPUTS  #################
    puts "######## FINAL REPORTS/OUTPUTS  #################"

    # output reports
    set stage route
    timeDesign -postRoute -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews
    timeDesign -postRoute -si -prefix ${stage}_si -outDir ../reports/${top_design}.innovus -expandedViews
    timeDesign -postRoute -hold -prefix $stage -outDir ../reports/${top_design}.innovus -expandedViews
    timeDesign -postRoute -hold -si -prefix ${stage}_si -outDir ../reports/${top_design}.innovus -expandedViews

    # output netlist.  Look in the Saved Design Directory for the netlist
    #write_hdl $top_design > ../outputs/${top_design}.$stage.vg
    saveNetlist ../outputs/${top_design}.$stage.innovus.vg 
    # there is not a command to just write the spef with a specific name, so use the Innovus command, then copy the file.
    saveModel -spef -dir ${top_design}_route_spef
    foreach i [glob ../outputs/${top_design}*innovus*.spef.gz] { file delete $i  }
    foreach i [glob ${top_design}_route_spef/*.spef.gz] { 
       set newfile [regsub ${top_design}_ [file tail $i] ${top_design}.route.innovus. ]
       file copy $i  ../outputs/$newfile 
    }

    puts "######## FINISHED ROUTE_OPT + FINAL REPORTS/OUTPUTS #################"
}

