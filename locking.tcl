### Locking library
### Use /tmp/tcl_device_locks/ for lock files (do you use tmpfs?).
### Files contain PID of creator and valid while it is running.

variable lock_folder "/tmp/tcl_device_locks"
variable lock_status 0

proc lock {name timeout {only_others 0} {async 0}} {
  if {$async} {
    after idle "lock_ $name $timeout $only_others $async"
    vwait ::lock_status
    if {$::lock_status} {error $::errorInfo}
  }\
  else {
    lock_ $name $timeout $only_others $async
  }
  return
}

proc lock_ {name timeout only_others async} {
  # check if lock folder exists:
  if { ! [file exists $::lock_folder] } {
    if {$async} {set ::lock_status 1}
    error "lock folder does not exist: $::lock_folder"
  }

  # set some parameters
  set fname "$::lock_folder/$name"; #lock file name
  set dt 100; # delay, ms

  if {$async==0} {
    # In sync version just try to grab lock in a cycle
    while {[catch {set fo [open $fname {WRONLY CREAT EXCL}]}]} {
      lock_check $name $only_others [expr $timeout<0]
      set timeout [expr $timeout-$dt]
      after $dt
    }
  }\
  else {
    # In async version try to grab lock once and recursively run lock_ again if needed
    if {[catch {set fo [open $fname {WRONLY CREAT EXCL}] }]} {
      if {[catch {lock_check $name $only_others [expr $timeout<0] }]} {
        set ::lock_status 1
      }\
      else {
        after $dt "lock_ $name [expr $timeout-$dt] $only_others $async"
      }
      return
    }
  }
  # We have the lock! Put some information in the file
  puts $fo [pid]
  puts $fo [info script]
  close $fo

  # for vwait in async version
  if {$async} {set ::lock_status 0}
}


proc unlock {name} {
  if { ! [file exists $::lock_folder] } {
    error "lock folder does not exist: $::lock_folder"
  }
  if {[catch { file delete "$::lock_folder/$name" }]} {
    error "error unlocking $name"
  }
}

# Try to find who grabbed the lock
# returns 0 in following cases:
#   lock does not exist;
#   lock exists, process which put it have finished, we can delete the lock file
#   lock exists, it was put by out process, only_others==1
# returns 1:
#   if lock exists and lock_error==0
# produce an error in following cases:
#   lock forder does not exist
#   lock is expired but we can not delete it (permissions)
#   lock exists and lock_error==1
#

proc lock_check {name {only_others 0} {lock_error 1}} {

  # check if lock folder exists:
  if { ! [file exists $::lock_folder] } {
    error "lock folder does not exist: $::lock_folder"
  }
  set fname "$::lock_folder/$name"; #lock file name

  set p {}; # pid
  set n {}; # name
  if {![catch {
    set fl [open $fname {RDONLY}]
    set p [gets $fl]
    set n [gets $fl]
    close $fl
  }]} {

    # if process which did this lock does not exist now (or lock-file is brocken):
    if { $p=={} || ![file isdirectory "/proc/$p"] } {
      # try to delete lock file
      if {[catch {file delete $fname}]} {
        error "Can't delete expired lock file (do it manually): $fname" }
      return 0
    }

    # if it is our lock and $only_others==1 - just return
    if {$only_others && $p == [pid]} { return 0}

    # if there is a lock - produce an error or return 1
    if {$lock_error} {
      if {$p == [pid]} {error "$name is locked by myself ($n: $p)"}\
      else {error "$name is locked by $n: $p"}
    }\
    else {
      return 1
    }
  }
  return 0
}

