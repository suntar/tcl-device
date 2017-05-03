#!/usr/bin/tclsh

lappend auto_path ..
package require Devices 1.0

Devices::TenmaPS ps /dev/ttyACM0

puts [ps cmd *IDN?]
ps cmd "BEEP0"
ps cmd OUT1
ps cmd VSET1:1
ps cmd ISET1:0.223
ps cmd OUT1

ps cmd errOUT1

puts [ps cmd *IDN?]
puts [ps cmd ISET1?]
puts [ps cmd IOUT1?]


