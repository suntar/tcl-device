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
## All these methods should prepare the answer and run one of
##   spp_server_async::ans <text>
##   spp_server_async::err <text>
## This commands can be run even after returning from a method, but only once!
##
## In case of fatal error method can run spp_server_async::fatal <text> and
## stop the server (now it is not fully supported).
##
## There is a function
##   spp_server_async::try <script>
## which runs a script, gets returned value or error, then
## executes spp_server_async::err or spp_server_async::ans



package require Itcl

namespace eval spp_server_async {
  set ch  {#}
  set ver {002}
  set int_type 0
  set srv {}
  set lst {}
  set cnt_cmd 0;  # command counter
  set cnt_ans -1; # answer/error counter (answer from server constructor will be 0)

  ##########################################################
  # Process an error.
  # If message is empty use $::errorInfo
  proc err {{msg {}}} {

    # increase answer counter and check that it matches the command counter:
    incr spp_server_async::cnt_ans
    if {$spp_server_async::cnt_ans != $spp_server_async::cnt_cmd} {
      fatal_msg "Some interactive method in SPP server $spp_server_async::srv generates two answers/errors."
    }

    # if msg is not defined use errorInfo
    if {$msg == {}} {set msg $::errorInfo}

    # Extract and print first line of msg
    set n [string first "\n" $msg]
    if {$n>0} { set msg [string range $msg 0 [expr $n-1]]}
    puts "${spp_server_async::ch}Error: $msg"

    # we want to exit after an error from server constructor:
    if {$spp_server_async::cnt_ans == 0} {exit}

    # we are ready to read new commands:
    fileevent stdin readable "spp_server_async::on_read"
  }

  ##########################################################
  # Process a fatal error.
  # If message is empty use $::errorInfo
  proc fatal {{msg {}}} {
    # if msg is not defined use errorInfo
    if {$msg == {}} {set msg $::errorInfo}

    # Extract and print first line of msg
    set n [string first "\n" $msg]
    if {$n>0} { set msg [string range $msg 0 [expr $n-1]]}
    puts "${spp_server_async::ch}Fatal: $msg"

    exit
  }

  ##########################################################
  # Process an answer.
  proc ans {{text {}}} {
    # increase answer counter and check that it matches the command counter:
    incr spp_server_async::cnt_ans
    if {$spp_server_async::cnt_ans != $spp_server_async::cnt_cmd} {
      fatal "Some interactive method in SPP server $spp_server_async::srv generates two answers/errors."
    }

    # protect special symbols in the begginning of the line
    if {$text ne {}} {
      regsub -all -line "^$spp_server_async::ch" $text "$spp_server_async::ch$spp_server_async::ch" text
      set res {}
      append res $text
      puts $res
    }

    # print answer:
    puts "${spp_server_async::ch}OK"

    # we are ready to read new commands:
    fileevent stdin readable "spp_server_async::on_read"
  }

  ##########################################################
  ## Run script, get returned value or error, then
  ## execute spp_server_async::err or spp_server_async::ans
  proc try {script} {
    if {[catch {
      set ret [eval $script]
    }]} {
      spp_server_async::err
    }\
    else {
      spp_server_async::ans $ret
    }
  }

  ##########################################################
  # Reading a command
  proc on_read {} {
    # clear the fileevent - we do not want to run two commands in parallel
    fileevent stdin readable ""
    gets stdin line
    incr spp_server_async::cnt_cmd

    # connection is closed:
    if {[eof stdin]} {itcl::delete object $spp_server_async::srv; exit}

    # skip empty lines:
    if {$line == {}} { ans {}; return }

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

  ##########################################################
  # register list of valid commands
  proc list {args} { set spp_server_async::lst {*}$args }

  ##########################################################
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
