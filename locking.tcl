### Locking library
### Use /tmp/tcl_device_locks/ for lock files (do you use tmpfs?).
### Files contain PID of creator and valid while it is running.

variable lock_folder "/tmp/tcl_device_locks"

proc lock {name} {
  # create folder for locks if needed
  if { ! [file exists $::lock_folder] } {
    file mkdir $::lock_folder
    file attributes $::lock_folder -permissions 0777
  }
  # set new lock (use unique tmp file and rename to avoid collisions)
  set fname "$::lock_folder/$name"
  set i [expr int(1000*rand())]
  while {[file exists [set ftmp $::lock_folder/tmp_${name}_${i}]]} {incr i}

  set f [open $ftmp w]
  puts $f [pid]
  puts $f [info script]
  close $f
  file rename -force $ftmp $fname
}

proc unlock {name} {
  if { ! [file exists $::lock_folder] } { return }
  set fname "$::lock_folder/$name"
  # We do not want to check that file exists, because
  # it can disappear before deleting.
  # Instead we just delete it and ignore possible errors.
  catch { file delete $fname }
}

# Wait for a lock.
# If only_others==1 then wait only for locks set up by other processes
# Note that in tcl one process can make io collisions.
proc lock_wait {name timeout {only_others 0}} {
  #create a unique global var
  set msgvar lock_msg_[expr int(1e10*rand())]
  global $msgvar
  set h [after idle lock_check $name $timeout $only_others $msgvar]
  vwait $msgvar
  after cancel $h
  set msg [set $msgvar]
  unset $msgvar
  if {$msg!={}} {error $msg}
}

proc lock_check {name timeout only_others msgvar} {
  upvar $msgvar msg
  # no lock folder
  if { ! [file exists $::lock_folder] } { return }

  set fname "$::lock_folder/$name"
  # return if we can't read process id and script name from file
  if [ catch {
    set f [open $fname r]
    set p [gets $f]
    set n [gets $f]
    close $f
  }] { set msg {}; return}

  # return if process which did this lock does not exist now
  if { ! [file isdirectory "/proc/$p"] } {set msg {}; return }

  # return if we want to see only other's lock and
  # existing lock is from our process
  if {$only_others && $p == [pid]} {set msg {}; return }

  # check timeout
  if {$timeout <= 0} {
    if {$p == [pid]} {set msg "$name is locked by myself ($n: $p)"}\
    else {set msg "$name is locked by $n: $p"}
    return
  }

  set dt 100
  after $dt lock_check $name [expr {$timeout-$dt}] $only_others $msgvar
}

