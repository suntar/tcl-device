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
  variable timeout 5000

  # open device
  constructor {pars} {
    set pp [split $pars ":"]
    set host      [lindex $pp 0]
    set gpib_addr [lindex $pp 1]
  }
  # set address before any operation
  method set_addr {dev} {
    $dev write "++addr" $timeout
    set a [$dev read $timeout]
    if { $a != $gpib_addr } {
      $dev write "++addr $gpib_addr" $timeout
    }
  }
  # write to device without reading answer
  method write {v} {
    set dev [Chan #auto [::socket $host 1234] $host]
    set_addr $dev
    $dev write "$v\n" $timeout
    itcl::delete object $dev
    return
  }
  # read from device
  method read {} {
    set dev [Chan #auto [::socket $host 1234] $host]
    set_addr $dev
    set ret [$dev read $timeout]
    itcl::delete object $dev
    return $ret
  }
  # write and then read
  method cmd {v} {
    set dev [Chan #auto [::socket $host 1234] $host]
    set_addr $dev
    $dev write "$v\n" $timeout
    if [regexp {\?} $v] { set ret [$dev read $timeout] }\
    else { set ret ""}
    itcl::delete object $dev
    return $ret
  }
}

###########################################################
# LXI device connected via ethernet. SCPI raw connection via port 5025
# parameters: <host>
itcl::class lxi_scpi_raw {
  variable dev
  variable timeout 5000

  # open device
  constructor {pars} {
    set host $pars
    set dev [Chan #auto [::socket $host 5025] $host]
  }
  # close device
  destructor {
    itcl::delete object $dev
  }
  # write to device without reading answer
  method write {v} {
    $dev write $v $timeout
  }
  # read from device
  method read {} {
    return [$dev read $timeout]
  }
  # write and then read
  method cmd {v} {
    set cmd $v
    $dev write $cmd $timeout
    if [regexp {\?} $cmd] { return [$dev read $timeout] }\
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
  variable del;     # read/write delay
  variable bufsize; # read buffer size

  # open device
  constructor {pars} {
    set dev [::open $pars RDWR]
    set del 50
    set bufsize 1024
    fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {v} {
    puts -nonewline $dev $v; # no newline!
    after $del
    flush $dev
  }
  # read from device
  method read {} {
    after $del
    return [::read $dev $bufsize]
  }
  # write and then read
  method cmd {v} {
    set cmd [string toupper $v]
    puts -nonewline $dev $cmd
    flush $dev
    after $del
    if {[regexp {\?} $cmd]>0} { return [::read $dev $bufsize] }\
    else {return ""}
  }
}
###########################################################

}; #namespace
