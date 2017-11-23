package require Itcl

# wrapper for channel to read/write with a timeout
# Usage:
#  Chan dev stdin
#  puts [dev read 1000]

itcl::class Chan {

  variable ch
  variable stop
  variable ret
  variable name; # user-readable name of the channel (for error messages)

  constructor {c {n ""}} {
    set ch   $c
    set name $n
    if {$n == {}} {set name $c} else {set name $n}
    fconfigure $ch -blocking false -buffering line
  }

  destructor {
    ::close $ch
  }

  method on_read {} {
    set ret [::gets $ch];
    set stop 1
  }

  method on_write {v} {
    ::puts $ch $v;
    set stop 1
  }

  method on_timeout {} {
    set stop 2
  }

  method read {timeout} {
    set stop 0
    set ret {}

    # non-blocking read
    if {$timeout == 0} {
      return [::gets $ch]
    }
    # we need to wait
    if {$timeout > 0} {
      set dd [after $timeout [list $this on_timeout]]
    }
    fileevent $ch readable [list $this on_read]
    vwait [itcl::scope stop]
    fileevent $ch readable {}
    if {$timeout > 0} {
      after cancel $dd;
      if {$stop == 2} {error "Read timeout: $name"}
    }
    return $ret
  }

  method write {v timeout} {
    set stop 0
    set ret {}
    set dd [after $timeout [list $this on_timeout]]
    fileevent $ch writable [list $this on_write $v]
    vwait [itcl::scope stop]
    fileevent $ch writable {}
    after cancel $dd;
    if {$stop == 2} {error "Write timeout: $name"}
    return $ret
  }

  method eof {} { ::eof $ch }

}

