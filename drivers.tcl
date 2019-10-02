## Connection drivers for the Device library.
## Here we do not want to know device commands,
## but only know how to open/close connection and read/write commands

package require Itcl

namespace eval conn_drivers {

###########################################################
# GPIB device connected through Prologix gpib2eth converter
# parameters: <host>:<gpib_addr>
#
# Prologix converter works only with one connection.
# We have to reopen it on each operation.
itcl::class gpib_prologix {
  variable host
  variable gpib_addr
  variable timeout 30000

  # open device
  constructor {pars} {
    set pp [split $pars ":"]
    set host      [lindex $pp 0]
    set gpib_addr [lindex $pp 1]
    # try to open gpib and poll the device
    set dev [open_]
    puts $dev "++spoll"
    set a [gets_timeout $dev $timeout]
    if {$a == {}} {error "can't open device: $host:$gpib_addr"}
    ::close $dev
  }

  # open device and set address if needed
  method open_ {} {
    set dev [::socket $host 1234]
    ::fconfigure $dev -blocking false -buffering line
    puts $dev "++addr"
    set a [gets_timeout $dev $timeout]
    if { $a != $gpib_addr } { puts $dev "++addr $gpib_addr" }
    return $dev
  }

  # write to device without reading answer
  method write {v} {
    set dev [open_]
    ::puts $dev "$v\n"
    ::close $dev
    return
  }
  # read from device
  method read {} {
    set dev [open_]
    set ret [gets_timeout $dev $timeout]
    ::close $dev
    return $ret
  }
  # write and then read if command ends in ?
  method cmd {v} {
    set dev [open_]
    ::puts $dev "$v\n"
    if [regexp {\?} $v] { set ret [gets_timeout $dev $timeout] }\
    else { set ret ""}
    ::close $dev
    return $ret
  }
  method spoll {v} {
    set dev [open_]
    ::puts $dev "++spoll\n"
    set ret [gets_timeout $dev $timeout]
    ::close $dev
    return $ret
  }
  method clr {v} {
    set dev [open_]
    ::puts $dev "++clr\n"
    ::close $dev
    return
  }
}

###########################################################
# usbtcm device
# parameters: character device
#
# timeout is set inside usbtcm driver
itcl::class usbtcm {
  variable dev

  # open device
  constructor {pars} {
    set dev [::open $pars w+]
    fconfigure $dev -blocking true -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {v} {
    ::puts $dev $v
  }
  # read from device
  method read {} {
    return [::gets $dev]
  }
  # write and then read
  method cmd {v} {
    ::puts $dev $v
    if [regexp {\?} $v] { return [::gets $dev] }\
    else {return ""}
  }
}

###########################################################
# Serial device.
# Works with old RS-232 SCPI devices such as Keysight/HP 34401.
# Device confiduration is needed: RS-232 9600 8N.
# parameters: character device
#
# timeout is set inside usbtcm driver
itcl::class serial {
  variable dev
  variable timeout 30000

  # open device
  constructor {pars} {
    set dev [::open $pars w+]
    fconfigure $dev -blocking true -translation auto -buffering line -handshake xonxoff\
                    -mode 9600,n,8,1 -timeout $timeout\
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {v} {
    ::puts $dev $v
  }
  # read from device
  method read {} {
    return [::gets $dev]
  }
  # write and then read
  method cmd {v} {
    ::puts $dev $v
    if [regexp {\?} $v] { return [::gets $dev] }\
    else {return ""}
  }
}

###########################################################
# LXI device connected via ethernet. SCPI raw connection via port 5025
# parameters: <host>
itcl::class lxi_scpi_raw {
  variable dev
  variable timeout 2000

  # open device
  constructor {pars} {
    set host $pars
    set dev [::socket $host 5025]
    ::fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {v} {
    ::puts $dev $v
  }
  # read from device
  method read {} {
    return [gets_timeout $dev $timeout]
  }
  # write and then read
  method cmd {v} {
    set cmd $v
    ::puts $dev $cmd
    if [regexp {\?} $cmd] { return [gets_timeout $dev $timeout] }\
    else {return ""}
  }
}

###########################################################
# Connection with GpibLib
# parameters same is in the GpibLib
itcl::class gpib {
  variable dev
  constructor {pars} {
    package require GpibLib
    # Previously I used #auto here, but
    # updated tcl-gpib start creating #auto command
    set dev [gpib_device $this:dev {*}$pars]
  }
  destructor { gpib_device delete $dev }
  method write {v} { $dev write $v }
  method read {} { return [$dev read ] }
  method cmd {v} {
    if [regexp {\?} $v] { return [$dev cmd_read $v] }\
    else {$dev write $v; return ""}
  }
}

###########################################################
# Simple pipe protocol. Parameter string is a command name
itcl::class spp {
  inherit ::spp_client
  constructor {pars} { ::spp_client::constructor "$pars" } { }
}

###########################################################
# Tenma power supply. It is a serial port connection,
# but with specific delays and without newline characters.
# parameters: character device (such as /dev/ttyACM0)
itcl::class tenma_ps {
  variable dev
  variable del 250; # read/write delay

  # open device
  constructor {pars} {
    set dev [::open $pars RDWR]
    fconfigure $dev -blocking false -translation binary
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {v} {
    set cmd [string toupper $v]
    puts -nonewline $dev $cmd; # no newline!
    flush $dev
  }
  # read from device
  method read {} {
    after $del
    return [::read $dev]
  }
  # write and then read
  method cmd {v} {
    set cmd [string toupper $v]
    puts -nonewline $dev $cmd
    flush $dev
    after $del
    set ret [::read $dev]
    # Translate status to a number.
    # (currently there is a problem sending bynary data through ssh/device)
    if {$cmd == {STATUS?}} {
      set tmp $ret
      set $ret 0
      binary scan $tmp cu ret
    }
    return $ret
  }
}
###########################################################

###########################################################
# Agilent VS leak detector.
# parameter: serial device name
# Use null-modem cable/adapter!
itcl::class leak_ag_vs {
  variable dev
  variable timeout 2000

  # open device
  constructor {pars} {
    set dev [::open $pars r+]
    fconfigure $dev -blocking true -translation cr\
                    -mode 9600,n,8,1 -handshake none -timeout $timeout\
  }
  # close device
  destructor {
    ::close $dev
  }

  # write to device without reading answer
  method write {v} {
    cmd $v
  }
  # read from device
  method read {} {
  }
  # write and then read
  method cmd {v} {
    if {[string toupper $v] == "*IDN?"} { return "Agilent VS leak detector" }
    ::puts $dev $v
    ::flush $dev
    # read char by char until "ok" or "#?"
    set l {}
    while {1} {
      set c [::read $dev 1]
      if {$c == ""} {error "leak_ag_vs driver: read timeout"}
      lappend l $c
      set status [join [lrange $l end-1 end] ""]
      if {$status == "ok" || $status == "#?"} break;
    }
    if {$status == "#?"} {error "leak_ag_vs driver: bad command: $v"}

    set res [join [lrange $l 0 end-2] ""]
    # extract echo
    set n [string first $v $res]
    if {$n<0} {error "leak_ag_vs driver: echo problem"}
    set n [expr $n+[string length $v]+1]
    return [string range $res $n end]
  }
}

###########################################################
# Use pico_rec/pico_osc programs as serial devices
# parameter: pseudo terminal name
# example:   osc1v  pico /dev/osc1
itcl::class pico {
  variable dev
  variable pts
  variable timeout 2000

  # open device
  constructor {pars} {
    set pts $pars
    clr
  }
  # close device
  destructor {
  }

  # write to device without reading answer
  method write {v} {
    cmd $v
  }
  # read from device
  method read {} {
  }
  # write and then read
  method cmd {v} {
    set dev [::open $pts r+]

    set opt_timeout "-timeout $timeout"
    # timeout doesn't work with 'wait' command
    if { $v == "wait" } { set opt_timeout "" }

    fconfigure $dev -blocking true -buffering line {*}$opt_timeout

    if {[catch {::puts "$dev" "$v";::flush $dev} err]} {
      error "pico driver: bad command: $v"
    }
    set res {}
    # read string by string until "#OK" or "#Error:"
    while {1} {
      set l ""
      # read string: char by char until "\n"
      while {1} {
        set c [::read $dev 1]
        if {$c == ""} {error "pico driver: read timeout"}
        if {$c == "\n"} break;
        append l $c
      }
      set status [string range $l 0 2]
      if {$status == "#OK" || $status == "#Er"} break;
      lappend res $l
    }
    if {$status == "#Er"} {
      set err [string range $l 8 end]
      error "pico driver: $err"
    }
    ::close $dev
    return $res
  }

  method clr {} {
    set dev [::open $pts r+]
    fconfigure $dev -blocking true -buffering line -timeout $timeout
    ::read $dev
    ::close $dev
  }
}
###########################################################


}; #namespace
