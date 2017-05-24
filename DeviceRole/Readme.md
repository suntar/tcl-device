# DeviceRole library
---

## Ideology

This is a tcl library for implementing some special roles of devices used
in the Device library. For example you have a multimeter. Device library
only knows a name of this device (say mult0) and how it is connected. It
can transfer commands to the device, but it knows nothing about its model
and capabilities.

DeviceRole library can autodetect device model and use a driver with some
standard commands. Client only knows, that the role of device "mult0" is
a "voltmeter", and thus it has a get_volt command.

Usage:
```tcl
Package require DeviceRole

set dev [DeviceRole mult0 voltmeter]
set v [dev get_volt]
```

This device roles are not universal. All real devices have different
capabilities. But in many cases some simple operations are needed, then
DeviceRole library can be useful. For example, a program for NMR
measurements can use a device with a "sweeper" role to sweep field (or
frequency), and a device with "gauge" role to perform some measurements
and get values. Various power supplies and lock-in amplifiers can be used
as these "sweeper" and "gauge" devices.

#### Channels

Sometimes it is useful to specify which "channel" of the device should be used
for the role. It can be done in this way. Consider a lock-in amplifier, which
has 4 auxilary outputs for setting DC voltage. Consider a device role
"voltage_supply" which can set voltage on any device. Then you can write
```tcl
set dev [DeviceRole lockin0:2 voltage_supply]
```
This means, that channel 2 of device lockin0 should be used as a "voltage_supply".

---
## Existing roles:

#### power_supply -- a power supply with constant current and constant voltage modes.

Parameters and commands (see power_supply.tcl):

```tcl
public variable max_i; # max current
public variable min_i; # min current
public variable max_v; # max voltage
public variable min_v; # min voltage
public variable min_i_step; # min step in current
public variable min_v_step; # min step in voltage

method set_volt {val}  # set maximum voltage
method set_curr {val}  # set current
method set_ovp  {val}  # set/unset overvoltage protaction
method set_ocp  {val}  # set/unset overcurrent protection
method get_curr {}     # measure actual value of voltage
method get_volt {}     # measure actual value of current
method cc_reset {}     # bring the device into a controlled state in a constant current mode
method get_stat {}     # get device status (short string to be shown in the user)
```

Supported devices:

* Keysight N6700B frame with N6762A and N6762A modules. Channel and range (for N6762A) can
  be selected.
* Korad/Velleman/Tenma 72-2550 power supply.
