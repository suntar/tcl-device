package provide Device 1.1
package require Itcl
package require Locking
package require GpibLib
package require Graphene

# Open any device, send scpi command and read response, close device.
#
# Usage:
#  Device lockin0
#  lockin0 cmd *IDN?
#
# Information about devices read from devices.txt file:
# name model driver parameters
#
# Supported drivers and parameters:
#  gpib_prologix <hostname>:<gpib_address> -- gpib device connected
#                         to prologix gpib to ethernet converter
#  lxi_scpi_raw <hostname> -- scpi_raw interface to lxi device
#  tenma_ps <char device>  -- tenma power supply
#
# Locking is done on every single input/output operation using Rota's Locking library
#
itcl::class Device {
  variable dev;    # device handle
  variable name;   # device name
  variable model;  # device model
  variable drv;    # device driver
  variable pars;   # driver parameters
  variable gpib_addr;   # gpib address (for gpib_prologix driver)
  variable lock;   # lock for the device

  ####################################################################
  constructor {} {
    # get device name (remove tcl namespace from $this)
    set name $this
    set drv  {}
    set cn [string last ":" $name]
    if {$cn >0} {set name [string range $name [expr $cn+1] end]}

    # get device parameters from devices.txt file
    set fp [open /etc/devices.txt]
    while { [gets $fp line] >= 0 } {

      # remove comments
      set cn [string first "#" $line]
      if {$cn==0} {continue}
      if {$cn>0} {set line [string range $line 0 [expr $cn-1]]}

      # split line
      set data [regexp -all -inline {\S+} $line]
      if { [lindex $data 0] == $name } {
        set model [lindex $data 1]
        set drv   [lindex $data 2]
        set pars  [lrange $data 3 end]
        break
      }
    }
    if { $drv eq "" } { error "Can't find device $name in /etc/devices.txt"}

    # open device
    switch $drv {
     gpib_prologix {
       set pp [split $pars ":"]
       set host      [lindex $pp 0]
       set gpib_addr [lindex $pp 1]
       set dev [::socket $host 1234]
       fconfigure $dev -blocking false -buffering line
     }
     lxi_scpi_raw {
       set host $pars
       set dev [::socket $host 5025]
       fconfigure $dev -blocking false -buffering line
     }
     tenma_ps {
       set dev [::open $pars RDWR]
       fconfigure $dev -blocking false  -buffering line
     }
     gpib {
       set dev [gpib_device gpib::$name {*}$pars]
     }
     graphene {
       set dev [graphene::open {*}$pars]
     }
     pico_rec {
       set dev [::open "| pico_rec -d $pars" RDWR]
       read_line_nb $dev 3000
     }
     default {puts "Unknown driver name in devices.txt"}
    }

    # initialize lock
    set lock [lock_init #auto $name]
  }

  destructor {
    switch $drv {
      gpib_prologix { ::close $dev}
      lxi_scpi_raw  { ::close $dev}
      tenma_ps      { ::close $dev}
      gpib          { gpib_device delete $dev}
      graphene      { graphene::close $dev}
      pico_rec      { ::close $dev}
    }
  }


  ####################################################################
  # run command, read response if needed
  method write {c} {

    after 1000 {
      puts "Device locking timeout"
      return
    }
    $lock wait
    $lock get
    set ret {}

    switch $drv {
     gpib_prologix {
       puts $dev $c
       flush $dev
     }
     lxi_scpi_raw {
       puts $dev $c
       flush $dev
     }
     tenma_ps {
       # no newline characters, timeouts are important!
       puts -nonewline $dev $c
       flush $dev
     }
     gpib { $dev write $c }
     pico_rec {
       puts $dev $c
       flush $dev
     }
     default {set ret "write is not supported by driver $drv" }
    }
    $lock release
    return $ret
  }

  ####################################################################
  # run command, read response if needed
  method cmd_read {c} {

    after 1000 {
      puts "Device locking timeout"
      return
    }
    $lock wait
    $lock get
    set ret {}

    switch $drv {
     gpib_prologix {
       puts $dev $c
       flush $dev
       set ret [read_line_nb $dev 1000]
     }
     lxi_scpi_raw {
       puts $dev $c
       flush $dev
       set ret [read_line_nb $dev 1000]
     }
     pico_rec {
       puts $dev $c
       flush $dev
       set ret [read_line_nb $dev 1000]
     }
     tenma_ps {
       # no newline characters, timeouts are important!
       puts -nonewline $dev $c
       flush $dev
       after 50
       set ret [read $dev 1024]
     }
     gpib {
       set ret [$dev cmd_read $c]
     }
     graphene {
       set ret [graphene::cmd $dev $c]
     }
     default {set ret "cmd_read is not supported by driver $drv" }
    }
    $lock release
    return $ret
  }

  ####################################################################
  # run command, read response if needed
  method read {c} {

    after 1000 {
      puts "Device locking timeout"
      return
    }
    $lock wait
    $lock get
    set ret {}

    switch $drv {
     pico_rec {
       set ret [read_line_nb $dev 1000]
     }
     default {set ret "read is not supported by driver $drv" }
    }
    $lock release
    return $ret
  }



  ####################################################################
  ## read a line until \n character or timeout
  ## dev should be configured with -blocking 0
  private method read_line_nb {dev timeout} {
    while {$timeout>0} {
      gets $dev res
      if { [string length $res] } {
        return $res
      }
      after 10
      set timeout [expr {$timeout-10}]
    }
  }

  # send command, read response if needed
  private method send_cmd_auto {dev cmd} {
    puts $dev $cmd
    flush $dev
    if {[string index $cmd end] == "?"} {
      return [read_line_nb $dev 1000]
    }
    return {}
  }

  # send command and read response 
  private method send_cmd_read {dev cmd} {
    puts $dev $cmd
    flush $dev
    return [read_line_nb $dev 1000]
  }

}
