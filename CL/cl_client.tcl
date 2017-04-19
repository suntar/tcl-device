## Server part of the command line interface.
## Usage:
##   cl_client conn $prog_name
##   conn cmd <command>
## Server errors are converted into tcl errors
## Server answers are returned as a list of lines

package require Itcl

itcl::class cl_client {
  variable conn
  variable ch
  variable ver

  constructor {prog_name} {
    set conn [::open "| $prog_name" RDWR]
    fconfigure $conn -buffering line
    if {![regexp {^(.)CL([0-9]+)$} [gets $conn] l ch ver]} {
      error "unknown protocol"}
    read_answer
  }

  destructor {
    ::close $conn
  }

  # write command, read response until OK or Error line
  method cmd {c} {
    puts $conn $c
    read_answer
  }

  method read_answer {} {
    set ret {}
    while {1} {
      if { [eof $conn] } {return $ret}
      set l [gets $conn]
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

