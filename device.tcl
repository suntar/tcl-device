package require Itcl

# Open any device, send command, read response, close device.
#
# Usage:
#  Device lockin0
#  lockin0 cmd *IDN?
#
# Information about devices read from devices.txt file:
# name driver parameters
#
# There are two levels of locking are implemented.
# - low-level locking is done on every single input/output operation
#   to prevent mixing read and write commands from different clients.
# - high level locking is done by lock/unlock methods to allow user
#    to grab the device completely for a long time.
#
itcl::class Device {
  variable dev;    # device handle
  variable name;   # device name
  variable drv;    # device driver
  variable pars;   # driver parameters

  # timeouts
  variable lock_timeout    5000; # user locks
  variable io_lock_timeout 5000; # io locks
  variable log_folder "/var/log/tcl-device";

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
        set drv   [lindex $data 1]
        set pars  [lrange $data 2 end]
        break
      }
    }
    if { $drv eq "" } { error "Can't find device $name in /etc/devices.txt"}

    # create the driver
    set e [catch {set dev [conn_drivers::$drv #auto $pars]} ]

    # log
    do_log "" "Opened by [info script]\n  Driver: $drv\n  Parameters: $pars"

    if {$e} {error $::errorInfo}
  }
  destructor {
    do_log "" "Closed by [info script]"
    itcl::delete object $dev
  }

  ####################################################################
  # run command, read response if needed
  method write {args} {
    update
    ::lock_check $name $lock_timeout 1
    ::lock io_$name $io_lock_timeout 0
    set cmd [join $args " "]

    # log command
    do_log ">>" $cmd

    # run the command
    set e [catch {set ret [$dev write $cmd]}]

    # log response (errors if any)
    do_log "<<" "" $e

    # unlock device before throwing an error
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return {}
  }

  ####################################################################
  # run command, read response if needed
  method cmd {args} {
    update
    ::lock_check $name $lock_timeout 1
    ::lock io_$name $io_lock_timeout 0

    set cmd [join $args " "]

    # log command
    do_log ">>" $cmd

    # run the command
    set ret {}
    set e [catch {set ret [$dev cmd $cmd]}]

    # log error or answer
    do_log "<<" $ret $e

    # unlock device before throwing an error
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return $ret
  }
  # alias
  method cmd_read {args} { cmd $args }

  ####################################################################
  # read response
  method read {} {
    update
    ::lock_check $name $lock_timeout 1
    ::lock io_$name $io_lock_timeout 0

    # run the command
    set ret {}
    set e [catch {set ret [$dev read]}]

    # log error or answer
    do_log "<<" $ret $e

    # unlock device before throwing an error
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return $ret
  }

  method do_log {pref msg {e 0}} {
    if {[file exists "$log_folder/$name"]} {
       set ll [open "$log_folder/$name" "a"]
       if {$e} {puts $ll "[clock seconds] [pid] Error: $::errorInfo\n"}\
       elseif {$msg != {}} {puts $ll "[clock seconds] [pid] $pref $msg"}
       close $ll
    }
  }

  ####################################################################
  # High-level lock commands.
  # If you want to grab the device for a long time, use this
  method lock {} {
    ::lock $name 0 1
  }
  method unlock {} {
    ::unlock $name
  }
}
