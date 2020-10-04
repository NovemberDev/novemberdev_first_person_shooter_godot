extends Node

# connect to this event from the object 
# that should handle the event
signal on_event_raised

# emit this event from the object that
# handled the event
signal on_event_handled

func raise_event(name, parameters = null):
	# You could do this from any script,
	# but doing it centralized allows more
	# debug flexibility
	print("Event raised: " + str(name))
	emit_signal("on_event_raised", { name = name, parameters = parameters })

# scripts that listen to events to do stuff
# should call this wrapper method
func handle_event(name, parameters = null):
	print("Event handled: " + str(name))
	emit_signal("on_event_handled", { name = name, parameters = parameters })
