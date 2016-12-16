package provide Device 1.2
package require Itcl
package require Locking

# Open any device, send command, read response, close device.
#
# Usage:
#  Device lockin0
#  lockin0 cmd *IDN?
#
# Information about devices read from devices.txt file:
# name model driver parameters
#
# Locking is done on every single input/output operation
# using Rota's Locking library.
# Higher-level locking may be needed on high-level operations
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
    set dev [conn_drivers::$drv #auto $pars]
    set lock [lock_init #auto device_lib_lock_for_$name]; # initialize lock
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
    $dev write $msg
    $lock release
    return $ret
  }

  ####################################################################
  # run command, read response if needed
  method cmd {msg} {
    after 1000 {
      puts "Device locking timeout"
      return
    }
    $lock wait
    $lock get
    set ret [ $dev cmd $msg ]
    $lock release
    return $ret
  }
  # alias
  method cmd_read {msg} { cmd $msg }

  ####################################################################
  # run command, read response if needed
  method read {c} {
    after 1000 {
      puts "Device locking timeout"
      return
    }
    $lock wait
    $lock get
    set ret [$dev read ]
    $lock release
    return $ret
  }

}
