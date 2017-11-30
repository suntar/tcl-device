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

## same but with vwait:
proc gets_timeout_async {chan timeout} {
  set ::chan_err($chan) 0
  set ::chan_ret($chan) {}

  fileevent $ch readable [list $this chan_on_read]
  if {$timeout >= 0} {
     set dd [after $timeout [list $this chan_on_timeout]] }

  vwait ::chan_err($chan)
  fileevent $ch readable {}
  after cancel $dd;
  if {$::chan_err($chan)} { error "Read timeout: $name" }

  return $::chan_ret{$chan}
}

proc chan_on_read {chan} {
  set ::chan_ret($chan) [::gets $ch];
  set ::chan_err($chan) 0
}

proc chan_on_timeout {chan} {
  set ::chan_err($chan) 1
}
