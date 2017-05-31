#!/usr/bin/tclsh

lappend auto_path ..
package require Locking

lock_init a name1
a get
after 1000 a release
a wait
puts "lock released"
