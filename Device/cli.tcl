## Standard command line interface for high-level devices.
## Usage:
##   cli::run $drv_class $opts
##
## $drv_class is an itcl class name, $opts are options for its constructor.
## The class should have methods
##   list -- returns list of methods for use in the command line interface.
##   <other methods> including ones listed in the list method.
##
## cli::run reads commands from stdin and runs corresponding methods
## from the list. If command exists and processed without errors then
## its output are printed to stdout, followed by OK line.
## In case of error "Error: ..." line is printed.
##
## The CLI interface is not properly defined yet.


namespace eval cli {

  # Extract and print first line of ::errorInfo
  proc print_err {} {
    set e $::errorInfo
    set n [string first "\n" $e]
    if {n>0} { set e [string range $e 0 [expr $n-1]]}
    puts "Error: $e"
  }

  # read command from stdin and write answer
  proc read_cmd {dev} {
    gets stdin line
    if {[eof stdin]} {exit}
    if {$line == {}} {return}
    set cmd [lindex $line 0]
    if { $cmd ni [$dev list]} {
      puts "Error: unknown command: $line"
      return
    }
    if {[catch {set ret [$dev {*}$line]}]} {
      cli::print_err
    } else {
      puts $ret
      puts OK
    }
  }

  # main loop
  proc run {drv_class opts} {
    set drv [$drv_class #auto $opts]
    if {$drv == ""} {exit}
    fconfigure stdin -buffering line
    fileevent stdin readable "cli::read_cmd $drv"
    vwait forever
  }

}
