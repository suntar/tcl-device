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
  variable logfile {}; # log file

  # timeouts
  variable lock_timeout    5000; # user locks
  variable io_lock_timeout 5000; # io locks

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
    set dev [conn_drivers::$drv #auto $pars]
  }
  destructor {
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
    # log answer
    if {$logfile!={}} {
      set ff [open $logfile "a"]
      puts $ff "$name << $ret"
      close $ff
    }
    set e [catch {set ret [$dev write [join $args " "]]}]
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
    if {$logfile!={}} {
      set ff [open $logfile "a"]
      puts $ff "$name << $cmd"
    }
    # run the command
    set e [catch {set ret [$dev cmd $cmd]}]

    # unlock device before throwing an error
    ::unlock io_$name
    if {$e} {error $::errorInfo}

    # log answer
    if {$logfile!={}} {
      if {$ret != {}} {puts $ff "$name >> $ret"}
      close $ff
    }
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
    set e [catch {set ret [$dev read]}]

    # unlock device before throwing an error
    ::unlock io_$name
    if {$e} {error $::errorInfo}

    # log answer
    if {$logfile!={}} {
      set ff [open $logfile "a"]
      puts $ff "$name >> $ret"
      close $ff
    }
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
  method set_logfile {f} {
    set logfile $f
  }
}
