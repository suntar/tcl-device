### Locking library
### Use /tmp/tcl_locking/ for lock files (do you use tmpfs?).
### Files contain PID of creator and valid while it is running.

proc lock {name} {

  # create folder for locks if needed
  set fdir  "/tmp/tcl_locks"
  if { ! [file exists $fdir] } {
    file mkdir $fdir
    chmod 777 $fdir
  }

  # check lockfile, wait
  set fname "$fdir/$name"
  # wait while lock file exists and its craetor is running 
  while {1} {
    if { ! [file exists $fname] } { break }
    set f [open $fname r]
    set p [gets $f]
    close $f
    if { ! [file isdirectory "/proc/$p"] } { break }
    after 100
  }

  # set new lock (use rename to prevent using temporary files)
  set ftmp "$fdir/tmp_$name"
  set f [open $ftmp w]
  puts $f [pid]
  close $f
  file rename -force $ftmp $fname
}

proc unlock {name} {
  set fdir  "/tmp/tcl_locks"
  if { ! [file exists $fdir] } { return }

  set fname "$fdir/$name"
  if { [file exists $fname] } {
    file delete $fname
  }
}