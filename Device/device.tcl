package provide Device 1.0
package require Itcl
package require Locking

# Open any device, send scpi command and read response, close device.
#
# Usage:
#  Device lockin0
#  lockin0 cmd *IDN?
#
# Information about devices read from devices.txt file:
# name driver parameters
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
  variable drv;    # device driver
  variable pars;   # driver parameters
  variable gpib_addr;   # gpib address (for gpib_prologix driver)
  variable lock;   # lock for the device

  ####################################################################
  constructor {} {
    # get device name
    set name $this
    set cn [string last ":" $name]
    if {$cn >0} {set name [string range $name [expr $cn+1] end]}

    # get device parameters from devices.txt file
    set fp [open /etc/devices.txt]
    while { [gets $fp line] } {

      # remove comments
      set cn [string first "#" $line]
      if {$cn==0} {continue}
      if {$cn>0} {set line [string range $line 0 [expr $cn-1]]}

      # split line
      set data [regexp -all -inline {\S+} $line]
      if { [lindex $data 0] == $name } {
        set drv  [lindex $data 1]
        set pars [lrange $data 2 end]
        break
      }
    }

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
     default {puts "Unknown driver name in devices.txt"}
    }

    # initialize lock
    set lock [lock_init #auto $name]
  }

  destructor { ::close $dev }

  ####################################################################
  # run command, read response if needed
  method cmd {c} {

    after 1000 {
      puts "Device locking timeout"
      return
    }
    $lock wait
    $lock get

    switch $drv {
     gpib_prologix {
       set a [send_cmd_read $dev "++addr" ]
       if { $a != $gpib_addr } { send_cmd $dev "++addr $gpib_addr" }
       set ret [send_cmd_auto $dev $c]
     }
     lxi_scpi_raw {
       set ret [send_cmd_auto $dev $c]
     }
     tenma_ps {
       # no newline characters, timeouts are important!
       puts -nonewline $dev $c
       flush $dev
       after 50
       if {[string index $c end] == "?"} {
         set ret [read $dev 1024]
         after 50
       } else {
         set ret {}
       }
     }
     default {set ret "Unknown driver name in devices.txt" }
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
