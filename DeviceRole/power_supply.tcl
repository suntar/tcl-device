######################################################################
# A power_supply role

package require Itcl
package require Device

namespace eval device_role::power_supply {
  variable role "power_supply"

  ## Detect device model, create and return driver object for it
  proc create {name chan} {
    # create device, ask for ID
    Device $name
    set ID [$name cmd *IDN?]

    set n [namespace current]
    set driver {}
    foreach m {keysight_n6700b tenma_72-2550} {
      set re [set ${n}::${m}::id_regexp]
      if {[regexp $re $ID]} {
        return ${n}::[$m #auto ${n}::${name} $chan]
      }
    }
    error "Do not know how to use device as a $n: $ID"
  }


  ## Interface class. All power_supply driver classes are children of it
  itcl::class interface {
    proc id_regex {} {}; ## return regexp for *IDN? response used to detect device model

    # variables which should be filled by driver:
    variable dev; ## Device handler (see Device library)
    public variable max_i; # max current
    public variable min_i; # min current
    public variable max_v; # max voltage
    public variable min_v; # min voltage
    public variable min_i_step; # min step in current
    public variable min_v_step; # min step in voltage

    # Drivers should provide constructor with "device" and "channel" parameters
    constructor {} {}
    # methods which should be defined by driver:
    method set_volt {val} {}; # set maximum voltage
    method set_curr {val} {}; # set current
    method set_ovp  {val} {}; # set/unset overvoltage protaction
    method set_ocp  {val} {}; # set/unset overcurrent protection
    method get_curr {} {};    # measure actual value of voltage
    method get_volt {} {};    # measure actual value of current

    ## cc_reset -- bring the device into a controlled state in a constant current mode.
    # If device in constant current mode it should do nothing.
    # If OVP is triggered, then set current to actial current value,
    # reset the OVP condition and and turn the output on.
    # This function should not do any current jumps.
    method cc_reset {} {}

    # get_stat -- get device status (short string to be shown in the interface).
    # Can have different values, depending on the device:
    #  CV  - constant voltage mode
    #  CC  - constant current mode
    #  OFF - turned off
    #  OV  - overvoltage protection triggered
    #  OC  - overcurent protection triggered
    # ...
    method get_stat {} {};

    method lock {} {$dev lock}
    method unlock {} {$dev unlock}
  }
}
