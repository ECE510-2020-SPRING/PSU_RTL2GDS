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



