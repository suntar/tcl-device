#!/usr/bin/tclsh

package provide OscCGR101 1.0

namespace eval cgr101 {

##################################################
# open the device and check its correct id
proc open {port} {
  global timeoutHandle
  global serialCheck
  global dev

  set dev [::open $port r+]
#  fconfigure $dev -handshake rtscts

  fileevent $dev readable {
    set incomingData [gets $dev]
    # puts "incomingData: $incomingData"
    if {  [lsearch $incomingData "CircuitGear"] !=-1 } {
      after cancel $timeoutHandle
      set serialCheck found
    }
  }

  set timeoutHandle [after 1500 {set serialCheck timeout}]
  set serialCheck waiting

  update
  puts $dev  "i"
  flush $dev

  vwait serialCheck
  puts "status: $serialCheck"

  if {$serialCheck == "found"} {
    return $dev
  } else {
    puts "Device not found"
    return 0
  }
}

# close the device
proc close {dev} {
  ::close $dev
}


##################################################
# get device id
proc get_id {dev} {
  puts $dev "i"
  flush $dev
  return [gets $dev]
}

# get device status
proc get_state {dev} {
  puts $dev "S S"
  flush $dev
  set s [gets $dev]
  return [lindex $s 1]
}

##################################################
# set generator frequency
proc set_freq {dev f} {
  set ph [expr {int($f/0.09313225746)} ]
  set f0 [expr {$ph % 256}]
  set f1 [expr {($ph/256) % 256}]
  set f2 [expr {($ph/65536) % 256}]
  set f3 [expr {($ph/16777216) % 256}]
  puts $dev "W F $f3 $f2 $f1 $f0"
  flush $dev
}
# set generator amplitude
proc set_amp {dev a} {
  puts $dev "W A $a"
  flush $dev
}

proc set_time {dev f} {
}


# read digital inputs
# do not work?!
proc get_di {dev} {
  puts $dev "D I"
  flush $dev
  return [gets $dev]
}

# set digital outputs
proc set_do {dev val} {
  puts $dev "D O $val"
  flush $dev
}

# start capture
proc go {dev val} {
  puts $dev "S G"
  flush $dev
}

# read data
proc read {dev} {
  puts $dev "S B"
  flush $dev
  return [::read $dev 4097]
}

}; #namespace
