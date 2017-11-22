## Server part of a simple pipe protocol interface
## Fully async version! Program can return their results from anywhere
#
## Usage:
##
## $server_class is an itcl class name, $opts are options for its constructor.
##
## Set interface type:
##   set spp_server::int_type <type>
##   type 0 (default):
##     The class should register some of its methods with spp_server_async::list command.
##     Commands read from stdin run corresponding methods.
##   type 1:
##     The class should have method `cmd` where all commands are passed as arguments
##
## Register a list of valid methods:
##   spp_server_async::list <list of valid commands>
##
## Run the server:
##   spp_server_async::run $server_class $opts
##
## "Interactive" methods of the class:
##  - each registered method for interface type 0;
##  - cmd method for interface type 1;
##  - class constructor.
## All these methods should prepare the answer and run a command
##   spp_server_async::answer <text>
## All these methods should catch errors and then run
##   spp_server_async::err
## This commands can be run even after returning from a method!

package require Itcl

namespace eval spp_server_async {
  set ch  {#}
  set ver {001}
  set int_type 0
  set srv {}
  set lst {}

  # Extract and print first line of ::errorInfo
  proc err {} {
    set e $::errorInfo
    set n [string first "\n" $e]
    if {n>0} { set e [string range $e 0 [expr $n-1]]}
    puts "${spp_server_async::ch}Error: $e"
    # we are ready to read new commands
    fileevent stdin readable "spp_server_async::on_read"
  }

  # Print answer
  proc ans {text} {
    if {$text ne {}} {
      # protect special symbols in the begginning of the line
      regsub -all -line "^$spp_server_async::ch" $text "$spp_server_async::ch$spp_server_async::ch" text
      set res {}
      append res $text
      puts $res
    }
    puts "${spp_server_async::ch}OK"
    # we are ready to read new commands
    fileevent stdin readable "spp_server_async::on_read"
  }

  # Reading a command
  proc on_read {} {
    # clear the fileevent - we do not want to run two commands in parallel
    fileevent stdin readable ""
    gets stdin line

    # connection is closed:
    if {[eof stdin]} {itcl::delete object $spp_server_async::srv; exit}

    # skip empty lines:
    if {$line == {}} { answer {}; return }

    ## interface type 0

    if {[ catch {
      if {$spp_server_async::int_type == 0} {
        set cmd [lindex $line 0]

        if { $cmd eq "list"} { ans $spp_server_async::lst; return 1}

        if { $cmd ni $spp_server_async::lst} { error "Unknown command: $cmd" }

        # run server method, return its output followed by OK or an Error:
        $spp_server_async::srv {*}$line
      }\
      else {  ## interface type 1
        $spp_server_async::srv cmd {*}$line
      }
    }]} { err }
  }

  # register list of valid commands
  proc list {args} { set spp_server_async::lst {*}$args }

  # main loop
  proc run {srv_class args} {
    # configure stdin
    fconfigure stdin -buffering line -blocking no

    # create the server object, close connection on error
    puts "${spp_server_async::ch}SPP${spp_server_async::ver}"
    set spp_server_async::srv [$srv_class #auto {*}$args]
    vwait forever
  }

}
