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
# If only_others==1 then wait only for lockes set up by other processes
# Note that in tcl one process can make io collisions.
#
proc lock_wait {name timeout {only_others 0}} {
  if { ! [file exists $::lock_folder] } { return }
  set fname "$::lock_folder/$name"

  # return if we can't read process id from file
  if [ catch {
    set f [open $fname r]
    set p [gets $f]
    close $f
  }] {return}

  if { ! [file isdirectory "/proc/$p"] } { return }
  if {$only_others && $p == [pid]} { return }

  set dt 100
  set timeout [expr {$timeout-$dt}]
  if {$timeout < 0} {error "Locking timeout: $name"}
  after 100 lock_wait $name $timeout $only_others
}
