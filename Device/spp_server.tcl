## Server part of a simple pipe protocol interface
## Usage:
##   spp_server::run $server_class $opts
##
## $server_class is an itcl class name, $opts are options for its constructor.
##
## spp_server::int_type == 0:
##   The class should have methods
##     list -- returns list of methods for use in the protocol.
##     <other methods> including ones listed in the list method.
##   spp_server::run reads commands from stdin and runs corresponding methods.
##   Then #OK or #Error line is printed.
##
## spp_server::int_type == 1:
##   The class should have method cmd where all commands are passed as arguments
##
## Printing messages should be done by spp_server::answer command.
##

package require Itcl

namespace eval spp_server {
  set ch  {#}
  set ver {001}
  set int_type 0

  # Extract and print first line of ::errorInfo
  proc _print_err {} {
    set e $::errorInfo
    set n [string first "\n" $e]
    if {n>0} { set e [string range $e 0 [expr $n-1]]}
    puts "${spp_server::ch}Error: $e"
  }
  # Print OK line
  proc _print_ok {} {
    puts "${spp_server::ch}OK"
  }

  # Print answer
  # protect special symbols in the begginning of the line
  proc answer {text} {
    if {$text eq {}} { return }
    regsub -all -line "^$spp_server::ch" $text "$spp_server::ch$spp_server::ch" text
    set res {}
    append res $text
    puts $res
  }

  # read request from stdin and write answer
  proc read_cmd {srv} {
    gets stdin line
    # connection is closed:
    if {[eof stdin]} {itcl::delete object $srv; exit}

    # skip empty lines:
    if {$line == {}} {return}

    if {$spp_server::int_type == 0} {  ## interface type 0
      set cmd [lindex $line 0]
      # get list of commands,
      # check if the first word is a valid command:
      if {[catch {set lst [$srv list]}]} {
        spp_server::_print_err
        return
      }
      if { $cmd ni $lst} {
        puts "${spp_server::ch}Error: Unknown command: $cmd"
        return
      }
      # run server method, return its output followed by OK or an Error:
      if {[catch {set ret [$srv {*}$line]}]} {
        spp_server::_print_err
        return
      }
    }\
    else {  ## interface type 1
      # run server method, return its output followed by OK or an Error:
      if {[catch {set ret [$srv cmd {*}$line]}]} {
        spp_server::_print_err
        return
      }
    }

    spp_server::answer $ret
    spp_server::_print_ok
    return
  }

  # main loop
  proc run {srv_class args} {
    # create the server object, close connection on error
    puts "${spp_server::ch}SPP${spp_server::ver}"
    if {[catch {set srv [$srv_class #auto {*}$args]}]} {
      spp_server::_print_err
      return
    }
    spp_server::_print_ok

    # read requests, run commands
    fconfigure stdin -buffering line -blocking no
    fileevent stdin readable "spp_server::read_cmd $srv"
    vwait forever
  }

}
