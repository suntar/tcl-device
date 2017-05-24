# Use Korad/Velleman/Tenma 72-2550 device in a power_suply role.
# See https://sigrok.org/wiki/Korad_KAxxxxP_series
#
# ID string:
#   KORADKA6003PV2.0
#
# No channels are supported

package require Itcl

itcl::class device_role::power_supply::tenma_72-2550 {
  inherit device_role::power_supply::interface

  common id_regexp {^KORADKA6003PV2.0}

  constructor {d ch} {
    set dev $d
    set max_i 3.09
    set min_i 0.0
    set max_v 60.0
    set min_v 0.0
    set min_i_step 0.001
    set min_v_step 0.01
  }

  method set_volt {val} {
    set val [expr {round($val*100)/100.0}]
    $dev cmd "VSET1:$val"
  }
  method set_curr {val} {
    set val [expr {round($val*1000)/1000.0}]
    $dev cmd "ISET1:$val"
  }
  method set_ovp  {val} {
    set_volt $val
    $dev cmd "OVP1"
  }
  method set_ocp  {val} {
    set_curr $val
    $dev cmd "OCP1"
  }
  method get_curr {} { return [$dev cmd "IOUT1?"] }
  method get_volt {} { return [$dev cmd "VOUT1?"] }

  method cc_reset {} {
    ## set current to actual current, turn output on
    set status [$dev cmd "STATUS?"]
    set c [$dev cmd "IOUT1?"]
    $dev cmd "ISET1:$c"
    $dev cmd "OUT1"
  }

  method get_stat {} {
    # error states
    binary scan [$dev cmd "STATUS?"] cu n
    if {$n==80 || $n==63}  {return CC}
    if {$n==79 || $n==81}  {return CV}
    return "OFF"
  }
}
