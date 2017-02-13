#!/usr/bin/tclsh

lappend auto_path ..
package require Device 1.3


### CLI driver example. It has two commands,
### write to save some value and read to get it.
### you can see errors:
###  - read when var is not set
###  - write 1


itcl::class CLIDriver {
  variable var
  constructor {opts} {
  }
  method list {} { return "list read write"}
  method read {} { return $var }
  method write {v} {
    if {$v == 1} {error "can't write 1"}
    set var $v
  }
}


cli::run CLIDriver $argv
