package require Itcl

# Gets with a timeout but without vwait (to avoid nested
# vwaits in complicated programs).
# Channel should be configured with
#   -blocking false -buffering line
proc gets_timeout {chan timeout} {
  set t 0
  set dt 1
  while {1} {
    set line [gets $chan]
    if {$line != {}} {return $line}

    if {$timeout <= 0} {error "read timeout"}

    if {$td < 100 } {set dt [expr 2*$dt]}
    set timeout [expr $timeout-$dt]
    after $dt
  }
}
