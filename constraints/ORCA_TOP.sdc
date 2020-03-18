switch $synopsys_program_name {
 "icc2_shell"  {
    puts " Creating ICC2 MCMM "
    create_mode func
    create_corner slow
    create_scenario -mode func -corner slow -name func_slow
    current_scenario func_slow
    set_operating_condition ss0p75vn40c -library saed32lvt_ss0p75vn40c
    #set_operating_conditions ss0p75vn40c -library saed32lvt_ss0p75vn40c
    read_parasitic_tech -tlup $tlu_dir/saed32nm_1p9m_Cmax.tluplus -layermap $tlu_dir/saed32nm_tf_itf_tluplus.map -name Cmax
    read_parasitic_tech -tlup $tlu_dir/saed32nm_1p9m_Cmin.tluplus -layermap $tlu_dir/saed32nm_tf_itf_tluplus.map -name Cmin
    set_parasitic_parameters -early_spec Cmax -early_temperature -40
    set_parasitic_parameters -late_spec Cmax -late_temperature -40
    #set_parasitic_parameters -early_spec 1p9m_Cmax -early_temperature 125 -corner default
    #set_parasitic_parameters -late_spec 1p9m_Cmax -late_temperature 125 -corner default

    #set_scenario_status  default -active false
    set_scenario_status func_slow -active true -hold true -setup true

    # If the flow variable is set, then we should be in regular APR flow and not the macro floorplanning mode
    # We want to use the UPF associated with the correct netlist.  APR flow uses DCT output.  Macro fp uses DC output.
    if { [info exists flow ] } {
        source ../../syn/outputs/ORCA_TOP.dct.upf
    } else {
        source ../../syn/outputs/ORCA_TOP.dc.upf
    }

    source ../../constraints/ORCA_TOP_func_worst.sdc
 }
 "dc_shell" {
     set upf_create_implicit_supply_sets false
    source ../../constraints/ORCA_TOP.upf
    set_operating_conditions ss0p75vn40c -library saed32lvt_ss0p75vn40c
    source ../../constraints/ORCA_TOP_func_worst.sdc

    # Define voltage area for DCT mode.  We define the mw_lib variable in DCT mode script.
    # In the ICC2_flow it is defined in ORCA_TOP.design_options.tcl. Slightly different syntax.
    if { [ info exists mw_lib ] } {
       create_voltage_area  -coordinate {{580 0} {1000 400}} -power_domain PD_RISC_CORE
    }
 }
 "pt_shell" {
    source $topdir/apr/outputs/ORCA_TOP.route2.upf
    switch $corner {
     "max" {
        set_operating_conditions ss0p75vn40c -library saed32lvt_ss0p75vn40c
        source $topdir/constraints/ORCA_TOP_func_worst.sdc
      }
     "min" {
        set_operating_conditions ff0p95vn40c -library saed32lvt_ff0p95vn40c
        source $topdir/constraints/ORCA_TOP_func_best.sdc
     }
    }
 }
}

