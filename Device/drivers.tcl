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
#  -read_timeout -- read timeout, ms
itcl::class gpib_prologix {
  variable dev
  variable gpib_addr
  variable read_timeout 1000

  # open device
  constructor {pars} {
    set pp [split $pars ":"]
    set host      [lindex $pp 0]
    set gpib_addr [lindex $pp 1]
    set dev [::socket $host 1234]
    fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # set address before any operation
  method set_addr {} {
    puts $dev "++addr"
    flush $dev
    set a [read_line_nb $dev $read_timeout]
    if { $a != $gpib_addr } {
      puts $dev "++addr $gpib_addr"
      flush $dev
    }
  }
  # write to device without reading answer
  method write {args} {
    set_addr
    puts $dev {*}$args
    flush $dev
  }
  # read from device
  method read {} {
    set_addr
    return [read_line_nb $dev $read_timeout]
  }
  # write and then read
  method cmd {args} {
    set_addr
    puts $dev {*}$args
    flush $dev
    return [read_line_nb $dev $read_timeout]
  }
}

###########################################################
# LXI device connected via ethernet. SCPI raw connection via port 5025
# parameters:
#  -hostname -- device hostname or ip-address
#  -read_timeout -- read timeout, ms
itcl::class lxi_scpi_raw {
  variable dev
  variable read_timeout 1000

  # open device
  constructor {pars} {
    set host $pars
    set dev [::socket $host 5025]
    fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {args} {
    puts $dev {*}$args
    flush $dev
  }
  # read from device
  method read {} {
    return [read_line_nb $dev $read_timeout]
  }
  # write and then read
  method cmd {args} {
    write {*}$args
    return [read_line_nb $dev $read_timeout]
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
  method cmd {args} { return [$dev cmd_read {*}$args ] }
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
    puts -nonewline $dev {*}$args
    flush $dev
    after $del
    return [::read $dev $bufsize]
  }
}
###########################################################

}; #namespace
