# Sample execution script for HIT-modeler application
# Require jars so the user doesn't have to load them on CP
dir = File.dirname(__FILE__)
Dir[dir + "/../jars/\*.jar"].each { |jar| require jar }
require dir + '/../src/modeler'
modeler = Modeler.new
modeler.set_visible true
