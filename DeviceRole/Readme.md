### DeviceRole library
---

This is a tcl library for implementing some special roles of devices used
in the Device library. For example you have a multimeter. Device libray
only knows what it is connected via gpib and can access it. But it knows
nothing about model of this multimeter and commands.

DeviceRole library has wrappers which can autodetect device model and
implement some standard commands. Client only knows, that the role of
device "mult0" is a "voltmeter", and thus it has a get_volt command.

Usage:
```tcl
Package require DeviceRole

set dev [DeviceRole #auto mult0 voltmeter]
set v [dev get_volt]
```

This device roles are not universal. All real devices have different
capabilities. But in many cases some simple operations are needed, then
SmartDev library can be useful. For example, a program for NMR
measurements can use a device with a "sweeper" role to sweep field (or
frequency), and a device with "gauge" role to perform some measurements
and get values. Various power supplies and lock-in amplifiers can be used
as these "sweeper" and "gauge" devices.

#### Channels

Sometimes it is useful to specify which "channel" of the device should be used
for the role. It can be done in this way. Consider a lock-in amplifier, which
has as an option 4 auxilary outputs for setting DC voltage. Consider a device role
"power_supply" which can set voltage on any device. Then you can write
```tcl
set dev [DeviceRole #auto lockin0:2 power_supply]
```
This means, that channel 2 of device lockin0 should be used as a "power_supply".
