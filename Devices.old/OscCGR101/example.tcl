#!/usr/bin/wish

set port /dev/ttyUSB0


lappend auto_path ..
package require OscCGR101 1.0
package require xBlt 3

blt::graph .p -highlightthickness 0
pack .p -fill both -expand yes -side top

checkbutton .b -text Crosshairs -variable v
pack .b -side top

checkbutton .b2 -text Readout -variable v2.
pack .b2 -side top



set dev [cgr101::open $port]

puts [cgr101::get_state $dev]
puts [cgr101::get_id $dev]
cgr101::set_do $dev 3

cgr101::go $dev 3
puts [cgr101::get_state $dev]
after 1000

puts [cgr101::get_state $dev]
puts [cgr101::read $dev]
puts [cgr101::get_state $dev]


#puts [cgr101::get_di $dev]

#puts $dev "I"
#puts [cgr101::gets $dev]
#puts [cgr101::get_id $dev]
#puts [cgr101::set_freq $dev 32334.1]
close $dev

