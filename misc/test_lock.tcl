#!/usr/bin/tclsh

# how lock_wait is done:

proc lock_wait {timeout} {

  #create a unique global var
  set i 0
  set msgvar [namespace current]::msg$i
  while { [info exists $msgvar] ||\
          [namespace exists $msgvar] ||\
          [llength [info commands $msgvar]] }\
  { set msgvar [namespace current]::msg[incr $i] }
  global $msgvar

  after idle lock_check $timeout $msgvar
  vwait $msgvar
  puts ">>> $msgvar [set $msgvar]"
  unset $msgvar
}

proc lock_check {timeout msgvar} {
  upvar $msgvar msg
  puts "$timeout"

  # check timeout
  if {$timeout <= 0} {
    set msg "stop"
    return
  }

  set dt 300
  after $dt lock_check [expr {$timeout-1}] $msgvar
}


proc w {} {
  puts "."
  after 50 w
}


w

lock_wait 10

lock_wait 8
