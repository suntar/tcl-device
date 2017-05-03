#!/usr/bin/wish

# example of monitoring program
lappend auto_path ..
lappend auto_path .
package require Device
package require GrapheneMonitor 1.1

source module_cpu_load.tcl
source module_cpu_temp.tcl

# local connection to the database, current folder
Device db_local
graphene::monitor mon db_local
mon configure -verb 1

mon add_module [cpu_temp #auto]
mon add_module [cpu_load #auto]

