#!/usr/bin/tclsh
package require Itcl

# wrapper for channel to read/write with a timeout

itcl::class Chan {

  variable ch
  variable stop
  variable ret

  constructor {c} {
    set ch $c
    fconfigure $ch -blocking false -buffering line
  }

  method on_read {} {
    set ret [gets $ch];
    set stop 1
  }

  method on_write {v} {
    puts $ch $v;
    set stop 1
  }

  method on_timeout {} {
    set stop 2
  }

  method read {timeout} {
    set stop 0
    set ret {}
    set dd [after $timeout [list $this on_timeout]]
    fileevent $ch readable [list $this on_read]
    vwait [itcl::scope stop]
    fileevent stdin readable {}
    after cancel $dd;
    if {$stop == 2} {error "Read tiemout"}
    return $ret
  }

  method write {v timeout} {
    set stop 0
    set ret {}
    set dd [after $timeout [list $this on_timeout]]
    fileevent $ch writable [list $this on_write $v]
    vwait [itcl::scope stop]
    fileevent stdin writable {}
    after cancel $dd;
    if {$stop == 2} {error "Write tiemout"}
    return $ret
  }
}

Chan dev stdin
puts [dev read 1000]
