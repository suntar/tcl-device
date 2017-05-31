package provide ParseOptions 2.0

proc parse_options {procname arglist optlist} {

  # scan optlist, set defaults, fill opts($optname)
  set help {}
  foreach {optnames varname defval descr} $optlist {
    foreach optname $optnames {set opts($optname) $varname}
    uplevel 1 [list set $varname $defval]
    set help "$help$optnames -- $descr (default: $defval)\n"
  }
  # scan arglist,
  foreach {opt val} $arglist {
    if {[info exists opts($opt)]} {
      uplevel 1 [list set $opts($opt) $val]
    } else {
      error "$procname: unknown option $opt.
Options:
$help"
    }
  }
  if {[llength $arglist] % 2 != 0} {
    error "$procname: no value provided for option [lindex $arglist end].\n"
  }
}
