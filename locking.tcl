### Locking library
### Use /tmp/tcl_device_locks/ for lock files (do you use tmpfs?).
### Files contain PID of creator and valid while it is running.

variable lock_folder "/tmp/tcl_device_locks"

proc lock {name timeout {only_others 0}} {
  # check if lock folder exists:
  if { ! [file exists $::lock_folder] } {
    error "lock folder does not exist: $::lock_folder"
  }

  # set some parameters
  set fname "$::lock_folder/$name"; #lock file name
  set t 0;    # waiting time, ms
  set dt 100; # delay, ms

  # try to grab lock
  while {[catch {set fo [open $fname {WRONLY CREAT EXCL}]}]} {

    # try to find who grabbed the lock
    set p {}; # pid
    set n {}; # name
    catch {
      set fl [open $fname {RDONLY}]
      set p [gets $fl]
      set n [gets $fl]
      close $fl
    }

    # if process which did this lock does not exist now:
    if { $p!={} && ! [file isdirectory "/proc/$p"] } {
      # try to delete lock file
      if {[catch {file delete $fname}]} {
        error "Can't delete expired lock file (do it manually): $fname" }
    }

    # if it is our lock and $only_others==1 - just return
    if {$only_others && $p == [pid]} { return }

    # check timeout
    if {$t > $timeout} {
      if {$p == [pid]} {error "$name is locked by myself ($n: $p)"}\
      else {error "$name is locked by $n: $p"}
    }

    set t [expr $t+$dt]
    after $dt
  }

  # We have the lock! Put some information in the file
  puts $fo [pid]
  puts $fo [info script]
  close $fo
  return
}

proc unlock {name} {
  if { ! [file exists $::lock_folder] } {
    error "lock folder does not exist: $::lock_folder"
  }
  if {[catch { file delete "$::lock_folder/$name" }]} {
    error "error unlocking $name"
  }
}

proc lock_check {name {only_others 0}} {

  # try to find who grabbed the lock
  set p {}; # pid
  set n {}; # name
  if {![catch {
    set fl [open $fname {RDONLY}]
    set p [gets $f]
    set n [gets $f]
    close $fl
  }]} {
    # if it is our lock and $only_others==1 - just return
    if {$only_others && $p == [pid]} { return }
    # if there is a lock - produce an error
    if {$p == [pid]} {error "$name is locked by myself ($n: $p)"}\
    else {error "$name is locked by $n: $p"}
  }
  return
}

