## Device library
---

This is a tcl library for making complicated experimental setups.

All operations are done using "devices". They can be physical devices
connected via some interface, or high-level programs which can use other
devices.

Using the library one can open a few devices, send commands and get
answers (or errors if any) from them. There is also a library for
writing programs which can work as "devices".

The library has a configuration file "/etc/devices.txt" which lists
all avalible devices. For example, line "generator gpib -board 0 -address 6"
says that communication with device "generator" is done using driver gpib
with parameters -board 0 -address 6.

Then one can do something like this:
```tcl
package require Device
Device generator
puts [generator cmd "*idn?"]
```

Note that library itself does not know anything about commands used by certain
device, it just provides connection. For the next layer see DeviceRole library.

Library provides IO locking (one device can be used by a few programs or
by severel threads in one program without collisions) and optional
high-level locking (one program can lock a device for a long time).

Library provides logging of all device communications: if there is a file
`/var/log/tcl-device/<name>` then all communication with the device
<name> is appended to this file. This allows to start/stop logging
without restarting and modifing programs.

## Interface (see `Device/device.tcl`)
---

* Device <name> -- open a device <name>. The command <name> is created to access the device.
* <name> cmd  -- Send a command and get answer
* <name> lock -- High-level lock. Lock lasts until the process is alive or until unlock
                 command is run. If device is locked, other communications with this
                 device generate an error after some timeout
* <name> unlock -- Unlock the device.

In case of error a tcl error is called. Use catch to process it.


## Drivers (see `Device/drivers.tcl`)
---

* gpib_prologix -- GPIB device connected through Prologix gpib2eth converter.

  Parameters: `<hostname>:<gpib address>`

* lxi_scpi_raw -- LXI device connected via ethernet (SCPI raw connection via port 5025).

  Parameters: `<hostname>`

* usbtcm -- devices controlled by usbtcm driver

  Parameters: character device (such as `/dev/usctcm0`).

* gpib -- Connection with linux-gpib library.

  Parameters:
  * -timeout
  * -eot
  * -secondary
  * -eos
  * -bufferlen
  * -address
  * -board
  * -trimleft
  * -trimright
  * -readymask
  * -waitready

* spp -- Simple pipe protocol for programs.

  Parameters: program name and arguments.

* tenma_ps -- Tenma power supply. It is a serial port connection,
  but with specific delays and without newline characters.

  Parameters: character device (such as `/dev/ttyACM0`).

* leak_ag_vs -- Agilent VS leak detector. Use null-modem cable/adapter!

  Parameter: character device name



## Simple pipe protocol (SPP)
---

### version 001

There are two programs, "server" and "client". Client runs the server
program and communicate with it using unix pipes. All data are read and
written line by line in a human-readable form if possible.

When connection is opened, server writes a line with the special symbol
('#' in this example, but it can be any symbol), protocol name and
version: `#SPP<version>`. Then it can write some text for the user which can be
ignored. Then it either writes `#Error: <message>` and exits or writes
`#OK` and start listening for user requests. Simbol '#' here is a special
symbol which was selected in the beginning of the conversation.

Request is one line of text.

Answer of the server is a few lines of text, followed by '#Error:
<message>' or '#OK' line. Lines of the answer text starting with the
'#' symbol should be protected by doubling the symbol.

It is recommended to implement *idn? command which returns ID of the
device.

### version 002

If any fatal error appear server can print a line `#Fatal: <message>`
and exit.

* TODO: requests with several lines
* TODO: timeouts, safe closing of the channel...
* TODO: raw data transfer

## Conversation example (see `spp_server_test.tcl program`):

```
$ ./spp_server_test.tcl
#SPP002
Welcome, dear user!
Please, type "help" if you do not know what to do.
#OK
h
#Error: Unknown command: h
help
spp_server_test -- an example of the command-line interface program.
Commands:
  write <k> <v> -- write value v into a memory slot k=0..9
  read <k>      -- read value from a memory slot k
  list -- list all commands
  help -- show this message

#OK
write 1 abc
#OK
read
#Error: wrong # args: should be "testSrv0 read k"
read 1
abc
#OK
```

## TCL interface (see `Device/spp_client.tcl`, `Device/spp_server.tcl`, `Device/spp_server_async.tcl`)

There is a simple tcl library to implement the protocol. To write the
server create an Itcl class with all needed commands (each gets any
number of argumets and returns answer or throws an error) and "list"
command which returns all command names which should be available through
the interface. Then run:

  cl_server::run $server_class $opts

To create a connection to a server:
  cl_client conn $prog_name

and run commands
  conn cmd <command>

See `Device/spp_server_test.tcl` and `Device/spp_client_test.tcl` programs.


## SPP programs which can be used as devices:

All this programs supports Simple pipe protocol (SPP) and can be run
from command line or through Device library.

* graphene -- database (https://github.com/slazav/graphene)
* pico_rec -- recording signals with Pico2440 oscilloscope (https://github.com/slazav/pico_osc)
* device   -- Transfer commands to a device. Can be used to talk to any device
              from command line or remotely.


## Remote communication

You can easily add remote devices using spp interface. In the
configuration file of the Device library it can be written as
```
lockin0          ssh <remote address> device -d lockin0
graphene_remote  ssh <remote address> graphene -i
```
(ssh access should be configured using keys, ssh-agent etc.)

## vwait problem

There are two places in the library (locks and reading from devices) which can be done
in syncroneous and asyncronious ways. For simple programs both ways are good; for
tk interfaces async version is better since id does not lock the interface; in some
complicated programs a nested vwait call can appear in async version causing a permanent lock.

I do not have a good solution yet, so I just have both versions which can be swiched by
Device::sync variable (default 0).



