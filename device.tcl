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
    set do_log [file exists "$log_folder/$name"]
    if {$do_log} {
       set ll [open "$log_folder/$name" "a"]
       puts $ll "[pid] Opened by [info script]"
       puts $ll "[pid] Driver: $drv"
       puts $ll "[pid] Parameters: $pars"
       if {$e} {puts $ll "Error: $::errorInfo\n"}
       close $ll
    }

    if {$e} {error $::errorInfo}
  }
  destructor {
    set do_log [file exists "$log_folder/$name"]
    if {$do_log} {
       set ll [open "$log_folder/$name" "a"]
       puts $ll "[pid] Closed by [info script]"
       close $ll
    }
    itcl::delete object $dev
  }

  ####################################################################
  # run command, read response if needed
  method write {args} {
    update
    ::lock_wait $name    $lock_timeout 1
    ::lock_wait io_$name $io_lock_timeout 0
    ::lock io_$name
    set cmd [join $args " "]

    # log command
    set do_log [file exists "$log_folder/$name"]
    if {$do_log} {
       set ll [open "$log_folder/$name" "a"]
       puts $ll "[pid] << $cmd"
    }

    # run the command
    set e [catch {set ret [$dev write $cmd]}]

    # log response (errors if any)
    if {$do_log} {
       if {$e} {puts $ll "[pid] Error: $::errorInfo"}
       close $ll
    }

    # unlock device before throwing an error
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return {}
  }

  ####################################################################
  # run command, read response if needed
  method cmd {args} {
    update
    ::lock_wait $name    $lock_timeout 1
    ::lock_wait io_$name $io_lock_timeout 0
    ::lock io_$name

    set cmd [join $args " "]

    # log command
    set do_log [file exists "$log_folder/$name"]
    if {$do_log} {
       set ll [open "$log_folder/$name" "a"]
       puts $ll "[pid] << $cmd"
    }

    # run the command
    set e [catch {set ret [$dev cmd $cmd]}]

    # log
    if {$do_log} {
       if {$e} {puts $ll "[pid] Error: $::errorInfo\n"}\
       elseif {$ret != {}} {puts $ll "[pid] >> $ret"}
       close $ll
    }

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
    ::lock_wait $name    $lock_timeout 1
    ::lock_wait io_$name $io_lock_timeout 0
    ::lock io_$name

    # run the command
    set e [catch {set ret [$dev read]}]

    # log error or answer
    set do_log [file exists "$log_folder/$name"]
    if {$do_log} {
       set ll [open "$log_folder/$name" "a"]
       if {$e} {puts $ll "[pid] Error: $::errorInfo\n"}\
       elseif {$ret != {}} {puts $ll "[pid] >> $ret"}
       close $ll
    }

    # unlock device before throwing an error
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return $ret
  }

  ####################################################################
  # High-level lock commands.
  # If you want to grab the device for a long time, use this
  method lock {} {
    ::lock_wait $name $lock_timeout 1
    ::lock $name
  }
  method unlock {} {
    ::unlock $name
  }
}
