#!/usr/bin/tclsh

lappend auto_path ..
package require Locking 2.0

puts "wait for lock..."
lock name1
puts "locking is done, waiting 10s..."
after 10000
puts "do unlock..."
unlock name1
puts "ok"
