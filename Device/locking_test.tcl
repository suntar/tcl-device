#!/usr/bin/tclsh

source locking.tcl

puts "wait for lock..."
lock name1 1000
puts "locking is done, waiting 10s..."
after 10000
puts "do unlock..."
unlock name1
puts "ok"
