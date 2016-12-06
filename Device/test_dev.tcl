#!/usr/bin/tclsh

lappend auto_path ..
package require Device 1.0

Device lockin0
puts [lockin0 cmd *IDN?]

Device dgen0
puts [dgen0 cmd *IDN?]

Device ps0
puts [ps0 cmd *IDN?]

