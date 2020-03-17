# This is design dependent code to put IOs on particular sides of the block

foreach i [join [get_attribute [ get_port rdata* ] full_name ] ] {
  insert_io  $i l 
}
foreach i [ join [get_attribute [ get_port wdata* ] full_name ] ] {
  insert_io  $i r 
}
foreach i { rempty wfull }  {
  insert_io  $i t 
}
foreach i { rrst_n rclk rinc wrst_n wclk2x wclk winc }  {
  insert_io  $i b 
}

# This just puts a sram in the design.  Not really related to IOs, but is a place to put it.
create_cell sram_example [ get_lib_cells saed32sram_*/SRAM1RW64x8 ] 


