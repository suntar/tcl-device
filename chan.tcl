package require Itcl

# Gets with a timeout but without vwait (to avoid nested
# vwaits in complicated programs).
# Channel should be configured with
#   -blocking false -buffering line
# if timeout < 0 wait forever

proc gets_timeout {chan timeout} {
  set inf [expr {$timeout <0}]

  set dt 1
  while {1} {
    set line [gets $chan]
    if {$line != {}} {return $line}

    if {!$inf} {
      if {$timeout <= 0} {error "read timeout"}
    }

    if {$dt < 100 } {
      set dt [expr 2*$dt]
    }

    if {!$inf} {
      set timeout [expr $timeout-$dt]
    }

    after $dt
  }
}
