#!/usr/bin/wish

package require BLT 2.4

############################################################
global press ann del stat
set del 1000
set stat 0

label  .pl -text "Add pressure point:"
entry  .pv -textvariable press -validatecommand press_add
button .pb -text "Add" -command press_add
grid .pl .pv .pb -sticky we

label  .al -text "Add annotation:"
entry  .av -textvariable ann
button .ab -text "Add" -command ann_add
grid .al .av .ab -sticky we

label  .dl -text "Delay between points (ms):"
entry  .dv -textvariable del
grid .dl .dv -sticky we

checkbutton .stat -text "run the experiment" -variable stat
grid .stat -sticky we

proc press_add {} {global press; puts "press add $press"}
proc ann_add {} {global ann; puts "annotation add $ann"}
proc start {} {global del; }
proc stop {} {}

proc run {} {
  global del stat
  if {$stat} {
    puts "+"
  } {
    puts "-"
    after 1000
  }
  after $del run
}

after idle run
