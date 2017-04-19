## Server part of the command line interface.
## Usage:
##   cl_server::run $server_class $opts
##
## $server_class is an itcl class name, $opts are options for its constructor.
## The class should have methods
##   list -- returns list of methods for use in the command line interface.
##   <other methods> including ones listed in the list method.
##
## cl_server::run reads commands from stdin and runs corresponding methods.
## If command exists and processed without errors then
## its output are printed to stdout, followed by #OK line.
## In case of error "#Error: ..." line is printed.
##

package require Itcl

namespace eval cl_server {
  set ch  {#}
  set ver {001}

  # Extract and print first line of ::errorInfo
  proc print_err {} {
    set e $::errorInfo
    set n [string first "\n" $e]
    if {n>0} { set e [string range $e 0 [expr $n-1]]}
    puts "${cl_server::ch}Error: $e"
  }

  proc print_prompt {} {
#    puts -nonewline "${cl_server::ch}>"
#    flush stdout
  }

  # read request from stdin and write answer
  proc read_cmd {srv} {
    gets stdin line
    # connection is closed:
    if {[eof stdin]} {itcl::delete object $srv; exit}

    # skip empty lines:
    if {$line == {}} {return}

    set cmd [lindex $line 0]
    # get list of commands,
    # check if the first word is a valid command:
    if {[catch {set lst [$srv list]}]} {
      cl_server::print_err
      cl_server::print_prompt
      return
    }
    if { $cmd ni $lst} {
      puts "${cl_server::ch}Error: Unknown command: $cmd"
      cl_server::print_prompt
      return
    }
    # run server method, return its output followed by OK or an Error:
    if {[catch {set ret [$srv {*}$line]}]} {
      cl_server::print_err
      cl_server::print_prompt
      return
    }
    if {$ret ne {}} {
      # protect '\' symbols in the begginning of the line
      regsub -all -line "^$cl_server::ch" $ret "$cl_server::ch$cl_server::ch" ret
      puts $ret
    }
    puts "${cl_server::ch}OK"
    cl_server::print_prompt
    return
  }

  # main loop
  proc run {srv_class args} {
    # create the server object, close connection on error
    puts "${cl_server::ch}CL${cl_server::ver}"
    if {[catch {set srv [$srv_class #auto {*}$args]}]} {
      cl_server::print_err
      exit
    }
    puts "${cl_server::ch}OK"
    cl_server::print_prompt

    # read requests, run commands
    fconfigure stdin -buffering line
    fileevent stdin readable "cl_server::read_cmd $srv"
    vwait forever
  }

}
