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
# LXI device connected via ethernet. SCPI raw connection via port 5025
# parameters: <host>
itcl::class lxi_scpi_raw {
  variable dev
  variable timeout 30000

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
    set dev [gpib_device #auto {*}$pars]
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
    return [::read $dev]
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
    # read all data if any
    fconfigure $dev -blocking false
    ::read $dev
    fconfigure $dev -blocking true

    #write the command
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

    # remove the "ok" suffix
    set res [join [lrange $l 0 end-2] ""]

    # find and remove echo
    set n [string first $v $res]
    if {$n<0} {error "leak_ag_vs driver: echo problem"}
    set n [expr $n+[string length $v]+1]
    return [string range $res $n end]
  }
}
###########################################################


}; #namespace
