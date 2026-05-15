extends Control

@onready var log_label := $MarginContainer/VBoxContainer/RichTextLabel

# Shared mutable dict for test assertions — lambdas mutate keys, never reassign the var.
var _results := {}

func _ready() -> void:
	if not OS.has_feature("ios"):
		_log("WARNING: Not running on iOS — plugin signals will not fire.")

	_log("Starting Quick RTDB Test...")

	FirebaseIOS.rtdb.write_task_completed.connect(func(res): _log("Write OK: " + str(res)))
	FirebaseIOS.rtdb.update_task_completed.connect(func(res): _log("Update OK: " + str(res)))
	FirebaseIOS.rtdb.delete_task_completed.connect(func(res): _log("Delete OK: " + str(res)))

	_test_sequence()


func _test_sequence() -> void:
	var test_path := "debug_test/data"

	# 1. Set Value
	_log("1. Testing set_value...")
	FirebaseIOS.rtdb.set_value(test_path, {"status": "online", "val": 10})

	await get_tree().create_timer(2.0).timeout

	# 2. Increment — partial update, other keys must survive
	_log("2. Testing increment (+5) via update_value...")
	FirebaseIOS.rtdb.update_value(test_path, {"val": FirebaseIOS.rtdb.increment(5)})

	await get_tree().create_timer(2.0).timeout

	# 3. Get Value — asserts val=15 and status survived the partial update
	_log("3. Testing get_value (expect status=online, val=15)...")
	var handler_3 = func(res): _results["get_3"] = res
	FirebaseIOS.rtdb.get_task_completed.connect(handler_3)
	FirebaseIOS.rtdb.get_value(test_path)
	await get_tree().create_timer(2.0).timeout
	FirebaseIOS.rtdb.get_task_completed.disconnect(handler_3)
	var r3: Dictionary = _results.get("get_3", {})
	var d3: Dictionary = r3.get("data", {})
	if r3.get("status") == true and d3.get("val") == 15 and d3.get("status") == "online":
		_log("   PASS: val=15, status=online survived partial update.")
	else:
		_log("   FAIL: got " + str(r3))

	# 4. Delete Value — set path, delete, get must return empty data
	_log("4. Testing delete_value...")
	var delete_path := "debug_test/delete_me"
	FirebaseIOS.rtdb.set_value(delete_path, {"temp": true})
	await get_tree().create_timer(1.0).timeout
	FirebaseIOS.rtdb.delete_value(delete_path)
	await get_tree().create_timer(1.0).timeout
	var handler_4 = func(res): _results["get_4"] = res
	FirebaseIOS.rtdb.get_task_completed.connect(handler_4)
	FirebaseIOS.rtdb.get_value(delete_path)
	await get_tree().create_timer(2.0).timeout
	FirebaseIOS.rtdb.get_task_completed.disconnect(handler_4)
	var r4: Dictionary = _results.get("get_4", {})
	var d4: Dictionary = r4.get("data", {})
	if r4.get("status") == true and d4.is_empty():
		_log("   PASS: data is empty after delete.")
	else:
		_log("   FAIL: expected empty data, got " + str(r4))

	# 5. Listen / Stop Listening
	_log("5. Testing listen/stop logic...")
	var listener_path := "debug_test/listener"
	var listen_state := {"count": 0}

	var listener_callable = func(path, _data):
		if path == listener_path:
			listen_state["count"] += 1
			_log("   [Signal] Received update for %s (Total: %d)" % [path, listen_state["count"]])

	FirebaseIOS.rtdb.db_value_changed.connect(listener_callable)
	_log("   Starting listen...")
	FirebaseIOS.rtdb.listen_to_path(listener_path)
	await get_tree().create_timer(1.0).timeout

	_log("   Triggering change 1 (Expect signal)...")
	FirebaseIOS.rtdb.set_value(listener_path, {"test": 1})
	await get_tree().create_timer(2.0).timeout

	_log("   Stopping listen...")
	FirebaseIOS.rtdb.stop_listening(listener_path)
	await get_tree().create_timer(1.0).timeout

	_log("   Triggering change 2 (Expect NO signal)...")
	FirebaseIOS.rtdb.set_value(listener_path, {"test": 2})
	await get_tree().create_timer(2.0).timeout

	if listen_state["count"] == 2:
		_log("   PASS: Stop listening worked (Total signals: 2).")
	else:
		_log("   FAIL: Stop listening failed! Received %d signals (Expected 2)." % listen_state["count"])

	FirebaseIOS.rtdb.db_value_changed.disconnect(listener_callable)

	# 6. Re-subscribe — listen_to_path twice without stopping; must replace, not stack
	# Expected: 2 initial signals (one per subscribe) + 1 data change = 3 total
	# Stacked (broken): 2 initials + 2 changes = 4 signals
	_log("6. Testing re-subscribe (listen_to_path twice on same path)...")
	var resub_path := "debug_test/resub"
	var resub_state := {"count": 0}

	var resub_callable = func(path, _data):
		if path == resub_path:
			resub_state["count"] += 1
			_log("   [Signal] Re-sub update for %s (Total: %d)" % [path, resub_state["count"]])

	FirebaseIOS.rtdb.db_value_changed.connect(resub_callable)
	_log("   First listen_to_path...")
	FirebaseIOS.rtdb.listen_to_path(resub_path)
	await get_tree().create_timer(1.0).timeout

	_log("   Second listen_to_path (must replace, not stack)...")
	FirebaseIOS.rtdb.listen_to_path(resub_path)
	await get_tree().create_timer(1.0).timeout

	_log("   Triggering data change (Expect exactly 1 signal)...")
	FirebaseIOS.rtdb.set_value(resub_path, {"resub": true, "t": Time.get_ticks_msec()})
	await get_tree().create_timer(2.0).timeout

	FirebaseIOS.rtdb.stop_listening(resub_path)
	FirebaseIOS.rtdb.db_value_changed.disconnect(resub_callable)

	if resub_state["count"] == 3:
		_log("   PASS: Re-subscribe replaced listener (2 initial + 1 change = 3 signals).")
	elif resub_state["count"] == 4:
		_log("   FAIL: Duplicate listeners! Listener stacked instead of replaced (4 signals).")
	else:
		_log("   UNEXPECTED: Got %d signals (Expected 3)." % resub_state["count"])

	_log("=== All tests complete — tap Copy Output to share results ===")


func _log(msg: String) -> void:
	print("[RTDB-TEST] ", msg)
	if log_label:
		log_label.text += "[%s] %s\n" % [Time.get_time_string_from_system(), msg]


func _on_copy_output_pressed() -> void:
	DisplayServer.clipboard_set(log_label.text)
	_log("Output copied to clipboard.")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))
