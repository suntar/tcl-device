######################################################################
# Usage:
#
#   set dev [DeviceRole ps0:1L power_supply]
#   $dev set_curr 0.1
#
# This means "use channel 1L of Device ps0 as a power_supply".
# power_supply commands can be founs in ./power_supply.tcl file.
# Channel can be sat for some devices, see power_supply/*.tcl

namespace eval device_role {}

proc DeviceRole {name role} {
  ## parse device name:
  set chan {}
  if {[regexp {^([^:]*):(.*)} $name x n c]} {
    set name $n
    set chan $c
  }\

  return [device_role::${role}::create $name $chan]
}
