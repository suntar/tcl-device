#!/usr/bin/tclsh

lappend auto_path ..
package require Device 1.1

#Device lockin0
#puts [lockin0 cmd *IDN?]

#Device dgen0
#puts [dgen0 cmd *IDN?]

#Device ps0
#puts [ps0 cmd *IDN?]

#Device mult_ag
#puts [mult_ag cmd_read "*IDN?"]

#Device db
#db cmd_read "create test1 DOUBLE"

Device osc0
puts [osc0 cmd_read "chan_set"]



