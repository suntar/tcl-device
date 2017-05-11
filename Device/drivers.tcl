## Connection drivers for the Device library.
## Here we do not want to know device commands,
## but only know how to open/close connection and read/write commands

package require Itcl

####################################################################
## read a line until \n character or timeout
## dev should be configured with -blocking 0
proc read_line_nb {dev timeout} {
  while {$timeout>0} {
    gets $dev res
    if { [string length $res] } { return $res }
    after 10
    set timeout [expr {$timeout-10}]
  }
}

namespace eval conn_drivers {

###########################################################
# GPIB device connected through Prologix gpib2eth converter
# parameters:
#  -hostname -- converter hostname or ip-address
#  -addr     -- device GPIB address
#  -timeout  -- i/o timeout, ms
itcl::class gpib_prologix {
  variable dev
  variable gpib_addr
  variable timeout 2000

  # open device
  constructor {pars} {
    set pp [split $pars ":"]
    set host      [lindex $pp 0]
    set gpib_addr [lindex $pp 1]
    set dev [Chan #auto [::socket $host 1234] $host]
  }
  # close device
  destructor {
    itcl::delete object $dev
  }
  # set address before any operation
  method set_addr {} {
    $dev write "++addr" $timeout
    set a [$dev read $timeout]
    if { $a != $gpib_addr } {
      $dev write "++addr $gpib_addr" $timeout
    }
  }
  # write to device without reading answer
  method write {args} {
    set_addr
    $dev write {*}$args $timeout
  }
  # read from device
  method read {} {
    set_addr
    return [$dev read $timeout]
  }
  # write and then read
  method cmd {args} {
    set_addr
    set cmd {*}$args
    $dev write $cmd $timeout
    if [regexp {\?\s*$} $cmd] { return [$dev read $timeout] }\
    else {return ""}
  }
}

###########################################################
# LXI device connected via ethernet. SCPI raw connection via port 5025
# parameters:
#  -hostname -- device hostname or ip-address
#  -timeout -- read timeout, ms
itcl::class lxi_scpi_raw {
  variable dev
  variable timeout 1000

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
  method write {args} {
    $dev write {*}$args $timeout
  }
  # read from device
  method read {} {
    return [$dev read $timeout]
  }
  # write and then read
  method cmd {args} {
    set cmd {*}$args
    $dev write $cmd $timeout
    if [regexp {\?\s*$} $cmd] { return [$dev read $timeout] }\
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
  method write {args} { $dev write {*}$args }
  method read {} { return [$dev read ] }
  method cmd {args} {
    set cmd {*}$args
    if [regexp {\?\s*$} $cmd] { return [$dev cmd_read {*}$args] }\
    else {$dev write {*}$args; return ""}
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
  method write {args} {
    puts -nonewline $dev {*}$args; # no newline!
    after $del
    flush $dev
  }
  # read from device
  method read {} {
    after $del
    return [::read $dev $bufsize]
  }
  # write and then read
  method cmd {args} {
    set cmd [string toupper {*}$args]
    puts -nonewline $dev $cmd
    flush $dev
    after $del
    if {[regexp {\?\s*$} $cmd]>0} { return [::read $dev $bufsize] }\
    else {return ""}
  }
}
###########################################################

}; #namespace
