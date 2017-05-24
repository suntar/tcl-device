# Use Keysight N6700B device in a power_suply role.
# ID string:
#  Agilent Technologies,N6700B,MY54010313,D.04.07
#
# Supported modules:
#  * N6731B
#  * N6762A
# Use channels 1..4
# For module N6762A use specify also range, L or H
#
# Example:
#  ps0:1H -- use device ps0, 1st channel (N6762A module in high range)
#  ps0:2L -- use device ps0, 2nd channel (N6762A module in low range)
#  ps0:3  -- use device ps0, 3rd channel (N6731B module)

package require Itcl

itcl::class device_role::power_supply::keysight_n6700b {
  inherit device_role::power_supply::interface

  variable chan;  # channel to use (1..4)
  variable range; # range to use (H/L)

  common id_regexp {,N6700B,}

  constructor {d ch} {
    set dev $d
    # parse channel name and range:
    if {![regexp {([0-4])([HL]?)} $ch x chan range]} {
      error "$this: bad channel setting: $ch"}

    # detect module type:
    set mod [$dev cmd "syst:chan:mod? (@$chan)"]
    set max_i [$dev cmd "curr:rang? (@$chan)"]
    set max_v [$dev cmd "volt:rang? (@$chan)"]
    switch -- $mod {
      N6731B {
        set min_i 0.06
        set min_i_step 1e-2
        set min_v 0
      }
      N6762A {
        # module has two current ranges: 0.1 and 3A
        switch -- $range {
          H {
            set R 3
            set min_i 1e-3;
            set min_i_step 1e-4
          }
          L {
            set R 0.09
            set min_i 1e-4;
            set min_i_step 2e-6
          }
          default { error "$this: unknown range for $mod: $range" }
        }
        $dev cmd "curr:rang $R,(@$chan)"
        set min_v 0
      }
      default { error "$this: unknown module: $mod"}
    }
  }

  method set_volt {val} { $dev cmd "volt $val,(@$chan)" }
  method set_curr {val} { $dev cmd "curr $val,(@$chan)" }
  method set_ovp  {val} { $dev cmd "volt:prot $val,(@$chan)" }
  method set_ocp  {val} { $dev cmd "curr:prot $val,(@$chan)" }
  method get_curr {} {return [$dev cmd "meas:curr? (@$chan)"]}
  method get_volt {} {return [$dev cmd "meas:volt? (@$chan)"]}

  method cc_reset {} {
    ## set current to actual current, turn output on
    set c [$dev cmd "meas:curr? (@$chan)"]
    $dev cmd "curr $c,(@$chan)"
    $dev cmd "outp:prot:cle (@$chan)"
    $dev cmd "outp on,(@$chan)"
  }

  method get_stat {} {
    # error states
    set n [$dev cmd "stat:ques:cond? (@$chan)"]
    if {! [string is integer $chan] } {return {}}
    if {$n & 1} {return OV}
    if {$n & 2} {return OC}
    if {$n & 4} {return PF}
    if {$n & 8} {return CP+}
    if {$n & 16} {return OT}
    if {$n & 32} {return CP-}
    if {$n & 64} {return OV-}
    if {$n & 128} {return LIM+}
    if {$n & 256} {return LIM-}
    if {$n & 512} {return INH}
    if {$n & 1024} {return UNR}
    if {$n & 2048} {return PROT}
    if {$n & 4096} {return OSC}
    set n [$dev cmd "stat:oper:cond? (@$chan)"]
    if {! [string is integer $n] } {return {}}
    if {$n & 1} {return CV}
    if {$n & 2} {return CC}
    if {$n & 4} {return OFF}
    return ""
  }

}
