# graphene::monitor module.
# Temperature measurement for 2nd sound experiment
# AG34401A measures resistance (manual range needed?)
# HP34401 measures applied voltage (to know current on the resistor)
package require Device

itcl::class therm2s {
  inherit graphene::monitor_module

  variable devR
  variable devU

  constructor {} {
    set dbname test/therm
    set tmin   1
    set tmax   10
    set atol   0
    set name   "Thermometer (R and U)"
    set cnames {R U}
    Device mult_ag
    Device mult_hp
  }

  method get {} {
    set R [mult_ag cmd meas:res?]
    set U [mult_hp cmd F1RAZ1N5T3]
    return "$R $U"
  }
}
