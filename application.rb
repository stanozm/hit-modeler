# Sample execution script for HIT-modeler application
require 'src/modeler'
puts "warning: all files in /jars/ directory should be on classpath"
modeler = Modeler.new
modeler.set_visible true