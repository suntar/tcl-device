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
# There are two levels of locking implemented using Rota's Locking library.
# - low-level locking is done on every single input/output operation
#   to prevent mixing read and write commands from different clients.
# - high level locking is done by lock/unlock methods to allow user
#    to grab the device completely for a long time.
#
itcl::class Device {
  variable dev;    # device handle
  variable name;   # device name
  variable model;  # device model
  variable drv;    # device driver
  variable pars;   # driver parameters
  variable gpib_addr;  # gpib address (for gpib_prologix driver)
  variable io_lock;    # low-level io lock for the device
  variable lock;       # high-level lock for the device

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
    set io_lock [lock_init #auto io_lock_for_$name]; # initialize io lock
    set lock [lock_init #auto lock_for_$name]; # initialize high-level lock
  }


  ####################################################################
  # run command, read response if needed
  method write {c} {
    set dd [after 1000 { puts "Device locking timeout"; return }]
    $io_lock wait
    $io_lock get
    after cancel $dd
    $dev write $msg
    $io_lock release
    return $ret
  }

  ####################################################################
  # run command, read response if needed
  method cmd {msg} {
    set dd [after 1000 { puts "Device locking timeout"; return }]
    $io_lock wait
    $io_lock get
    after cancel $dd
    set ret [ $dev cmd $msg ]
    $io_lock release
    return $ret
  }
  # alias
  method cmd_read {msg} { cmd $msg }

  ####################################################################
  # read response
  method read {c} {
    set dd [after 1000 { puts "Device locking timeout"; return }]
    $io_lock wait
    $io_lock get
    after cancel $dd
    set ret [$dev read ]
    $io_lock release
    return $ret
  }

  ####################################################################
  # High-level lock commands.
  # If you want to grab the device for a long time, use this
  method lock {} {
    set dd [after 1000 { error "Device is locked" }]
    $lock wait
    $lock get
    after cancel $dd
  }
  method unlock {
    $lock release
  }

}
