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
  # set new lock (use rename to prevent using temporary files)
  set fname "$::lock_folder/$name"
  set ftmp  "$::lock_folder/tmp_$name"
  set f [open $ftmp w]
  puts $f [pid]
  close $f
  file rename -force $ftmp $fname
}

proc unlock {name} {
  if { ! [file exists $::lock_folder] } { return }
  set fname "$::lock_folder/$name"
  if { [file exists $fname] } { file delete $fname }
}

proc lock_wait {name timeout} {
  if { ! [file exists $::lock_folder] } { return }

  # check lockfile, wait
  set fname "$::lock_folder/$name"
  # wait while lock file exists and its creator is running
  set dt 100
  while {1} {
    if { ! [file exists $fname] } { break }
    set f [open $fname r]
    set p [gets $f]
    close $f
    if { ! [file isdirectory "/proc/$p"] } { break }
    if {$p == [pid]} { break }
    after 100
    set timeout [expr {$timeout-$dt}]
    if {$timeout < 0} {error "Locking timeout: $name"}
  }
}