## Server part of the command line interface.
## Usage:
##   spp_client conn $prog_name
##   conn cmd <command>
## Server errors are converted into tcl errors
## Server answers are returned as a list of lines

package require Itcl

itcl::class spp_client {
  variable conn
  variable ch
  variable ver
  variable timeout 2000

  constructor {prog_name} {
    set conn [Chan #auto [::open "| $prog_name" RDWR] $prog_name]
    if [$conn eof] {
      error "$prog_name: unknown protocol"}
    set l [$conn read $timeout]
    if {![regexp {^(.)SPP([0-9]+)$} $l l ch ver]} {
      error "$prog_name: unknown protocol"}
    if {$ver != 001} {
      error "$prog_name: unknown protocol version"}
    read
  }

  destructor {
    ::close $conn
  }

  # write command, read response until #OK or #Error line
  method cmd {c} {
    $conn write $c $timeout
    read
  }

  # separate commands for reading and writing
  method write {c} {
    $conn write $c $timeout
  }

  method read {} {
    set ret {}
    while {1} {
      if [$conn eof] {return $ret}
      set l [$conn read $timeout]
      if { [regexp "^${ch}${ch}" $l] } { set l [string range $l 1 end] }\
      else {
        if { [regexp -nocase "^${ch}Error: (.*)\$" $l e1 e2] } { error $e2 }
        if { [regexp -nocase "^${ch}OK\$" $l]} { return $ret }
        if { [regexp {^${ch}} $l] } {
          error "symbol ${ch} in the beginning of a line is not protected"
        }
      }
      lappend ret $l
    }
  }

}

