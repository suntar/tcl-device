#!/usr/bin/wish

# example of monitoring program
lappend auto_path ..
package require Device
package require GrapheneMonitor

source module_cpu_load.tcl
source module_cpu_temp.tcl
source module_capbr_v.tcl
source module_hp34401_pt1000.tcl

source module_lockin_sweep.tcl
#source module_therm2s.tcl

# local connection to the database, current folder

Device db_local

catch { db_local cmd create he4s/lockin_sweep double }

graphene::monitor mon db_local
mon configure -verb 1

#mon add_module [therm2s #auto]
mon add_module [lockin_sweep #auto]

