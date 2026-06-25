extends Control

@onready var log_label: RichTextLabel = $SafeAreaContainer/VBoxContainer/LogPanel/Log
@onready var buttons: VBoxContainer = $SafeAreaContainer/VBoxContainer/ScrollContainer/VBoxContainer

const TIMEOUT := 8.0

var _running := false

func _ready() -> void:
	_log_line("Firebase iOS — Automatic Tests")
	_log_line("Tap a feature to run its scripted test.")
	if not _firebase_ready():
		_log_line("")
		_warn("Firebase not active — running in editor or without iOS plugin.")
		_warn("Tests will report SKIPPED. Run on a real iOS device with GoogleService-Info.plist.")

func _firebase_ready() -> bool:
	return OS.has_feature("ios") and typeof(FirebaseIOS) == TYPE_OBJECT

# --- Test entry points ---

func _on_auth_pressed() -> void:
	await _run("Authentication", _test_auth)

func _on_firestore_pressed() -> void:
	await _run("Cloud Firestore", _test_firestore)

func _on_rtdb_pressed() -> void:
	await _run("Realtime Database", _test_rtdb)

func _on_messaging_pressed() -> void:
	await _run("Messaging", _test_messaging)

func _on_analytics_pressed() -> void:
	await _run("Analytics", _test_analytics)

func _on_remote_config_pressed() -> void:
	await _run("Remote Config", _test_remote_config)

func _run(title: String, test: Callable) -> void:
	if _running:
		return
	_running = true
	buttons.modulate = Color(1, 1, 1, 0.5)
	_log_line("")
	_log_line("=== %s ===" % title)
	if not _firebase_ready():
		_skip("requires a real iOS device with Firebase configured")
	else:
		await test.call()
	_log_line("=== %s done ===" % title)
	buttons.modulate = Color(1, 1, 1, 1)
	_running = false

# --- Scripted tests ---

func _test_auth() -> void:
	var auth: Object = FirebaseIOS.auth
	_step("sign_in_anonymously")
	auth.sign_in_anonymously()
	var res := await _race(auth.auth_success, auth.auth_failure)
	if res.index == 0:
		_pass("signed in: %s" % str(res.args))
	elif res.index == 1:
		_fail("auth_failure: %s" % str(res.args))
	else:
		_fail("timed out waiting for auth result")
		return

	_step("is_signed_in")
	if auth.is_signed_in():
		_pass("is_signed_in true")
	else:
		_fail("is_signed_in false after sign-in")

	_step("sign_out")
	auth.sign_out()
	var out: Variant = await _wait(auth.sign_out_success)
	if out != null:
		_pass("sign_out_success: %s" % str(out))
	else:
		_fail("timed out waiting for sign_out_success")

func _test_firestore() -> void:
	var fs: Object = FirebaseIOS.firestore
	var coll := "demo_auto_test"
	var doc := "doc_%d" % Time.get_unix_time_from_system()

	_step("set_document")
	fs.set_document(coll, doc, {"name": "demo", "count": 1})
	var w: Variant = await _wait(fs.write_task_completed)
	if w != null and _ok(w[0]):
		_pass("write ok: %s" % str(w[0]))
	else:
		_fail("write failed/timeout: %s" % str(w))

	_step("get_document")
	fs.get_document(coll, doc)
	var g: Variant = await _wait(fs.get_task_completed)
	if g != null and _ok(g[0]):
		_pass("get ok: %s" % str(g[0].get("data", g[0])))
	else:
		_fail("get failed/timeout: %s" % str(g))

	_step("delete_document")
	fs.delete_document(coll, doc)
	var d: Variant = await _wait(fs.delete_task_completed)
	if d != null and _ok(d[0]):
		_pass("delete ok")
	else:
		_fail("delete failed/timeout: %s" % str(d))

func _test_rtdb() -> void:
	var rtdb: Object = FirebaseIOS.rtdb
	var path := "debug_test/auto"

	_step("set_value")
	rtdb.set_value(path, {"status": "online", "val": 10})
	var w: Variant = await _wait(rtdb.write_task_completed)
	if w == null:
		_fail("set_value timeout")
		return
	_pass("set_value ok")

	_step("update_value (increment +5)")
	rtdb.update_value(path, {"val": rtdb.increment(5)})
	var u: Variant = await _wait(rtdb.update_task_completed)
	if u == null:
		_fail("update_value timeout")
	else:
		_pass("update_value ok")

	_step("get_value (expect val=15, status=online)")
	rtdb.get_value(path)
	var g: Variant = await _wait(rtdb.get_task_completed)
	if g != null and _ok(g[0]):
		var data: Dictionary = g[0].get("data", {})
		if data.get("val") == 15 and data.get("status") == "online":
			_pass("val=15, status survived partial update")
		else:
			_fail("unexpected data: %s" % str(data))
	else:
		_fail("get_value failed/timeout: %s" % str(g))

	_step("delete_value")
	var del_path := "debug_test/auto_delete"
	rtdb.set_value(del_path, {"temp": true})
	await _wait(rtdb.write_task_completed)
	rtdb.delete_value(del_path)
	var d: Variant = await _wait(rtdb.delete_task_completed)
	if d == null:
		_fail("delete_value timeout")
	else:
		rtdb.get_value(del_path)
		var g2: Variant = await _wait(rtdb.get_task_completed)
		if g2 != null and (g2[0].get("data", {}) as Dictionary).is_empty():
			_pass("data empty after delete")
		else:
			_fail("data not empty after delete: %s" % str(g2))

	_step("listen / stop_listening")
	var listen_path := "debug_test/auto_listen"
	var state := {"count": 0}
	var listener := func(p: String, _data: Dictionary) -> void:
		if p == listen_path:
			state["count"] += 1
	rtdb.db_value_changed.connect(listener)
	rtdb.listen_to_path(listen_path)
	await _delay(1.0)
	rtdb.set_value(listen_path, {"test": 1})
	await _delay(2.0)
	rtdb.stop_listening(listen_path)
	await _delay(1.0)
	rtdb.set_value(listen_path, {"test": 2})
	await _delay(2.0)
	rtdb.db_value_changed.disconnect(listener)
	if state["count"] == 2:
		_pass("stop_listening worked (2 signals)")
	else:
		_fail("expected 2 signals, got %d" % state["count"])

func _test_messaging() -> void:
	var msg: Object = FirebaseIOS.messaging

	_step("request_permission")
	msg.request_permission()
	var p: Variant = await _wait(msg.permission_result)
	if p != null:
		_pass("permission_result granted=%s" % str(p[0]))
	else:
		_warn("no permission_result within timeout (may need user prompt)")

	_step("get_token")
	msg.get_token()
	var res := await _race(msg.token_received, msg.token_error)
	if res.index == 0:
		var token := str(res.args[0])
		_pass("token received (%d chars)" % token.length())
	elif res.index == 1:
		_fail("token_error: %s" % str(res.args))
	else:
		_fail("timed out waiting for FCM token")

	_step("subscribe_to_topic")
	msg.subscribe_to_topic("demo_topic")
	var sub := await _race(msg.topic_subscribe_success, msg.topic_subscribe_failure)
	if sub.index == 0:
		_pass("subscribed to %s" % str(sub.args))
	elif sub.index == 1:
		_fail("subscribe failure: %s" % str(sub.args))
	else:
		_fail("timed out waiting for subscribe result")

func _test_analytics() -> void:
	# Analytics has no completion signals; verify calls return without error.
	var an: Object = FirebaseIOS.analytics

	_step("log_event")
	an.log_event("demo_auto_event", {"source": "auto_test", "value": 1})
	_pass("log_event dispatched (no completion signal)")

	_step("set_user_property")
	an.set_user_property("demo", "test_group")
	_pass("set_user_property dispatched")

	_step("get_app_instance_id")
	var id: String = an.get_app_instance_id()
	if id != "":
		_pass("app_instance_id: %s" % id)
	else:
		_warn("app_instance_id empty (may be unavailable)")

func _test_remote_config() -> void:
	var rc: Object = FirebaseIOS.remote_config

	_step("set_defaults")
	rc.set_defaults({"demo_flag": "default_value"})
	_pass("defaults set")

	_step("fetch_and_activate")
	rc.fetch_and_activate()
	var res := await _race(rc.activate_completed, rc.fetch_completed)
	if res.index >= 0:
		_pass("fetch/activate completed: %s" % str(res.args))
	else:
		_fail("timed out waiting for fetch/activate")
		return

	_step("get_string(demo_flag)")
	var val: String = rc.get_string("demo_flag")
	_pass("demo_flag = '%s' (source %d)" % [val, rc.get_value_source("demo_flag")])

# --- Await helpers ---

# Waits for a single signal OR timeout. Returns the emitted args as Array, or null on timeout.
func _wait(sig: Signal, timeout: float = TIMEOUT) -> Variant:
	var res := await _race(sig, Signal(), timeout)
	if res.index == 0:
		return res.args
	return null

# Races up to two signals against a timeout.
# Returns { "index": 0|1|-1, "args": Array }. index -1 means timeout.
func _race(sig_a: Signal, sig_b: Signal, timeout: float = TIMEOUT) -> Dictionary:
	var box := {"index": -1, "args": []}
	var handler_a := _make_handler(box, 0)
	var handler_b: Callable
	if not sig_a.is_null():
		sig_a.connect(handler_a)
	if not sig_b.is_null():
		handler_b = _make_handler(box, 1)
		sig_b.connect(handler_b)

	var timer := get_tree().create_timer(timeout)
	while box["index"] == -1 and timer.time_left > 0.0:
		await get_tree().process_frame

	if not sig_a.is_null() and sig_a.is_connected(handler_a):
		sig_a.disconnect(handler_a)
	if not sig_b.is_null() and sig_b.is_connected(handler_b):
		sig_b.disconnect(handler_b)
	return box

# Returns a Callable that records the first emission. Covers signals of 0..2 args.
func _make_handler(box: Dictionary, index: int) -> Callable:
	return func(a = null, b = null) -> void:
		if box["index"] != -1:
			return
		box["index"] = index
		var args: Array = []
		if b != null:
			args = [a, b]
		elif a != null:
			args = [a]
		box["args"] = args

func _delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _ok(result: Variant) -> bool:
	if result is Dictionary:
		return result.get("status", true) != false
	return result != null

# --- Logging ---

func _step(name: String) -> void:
	_log_line("[color=#8aa]> %s[/color]" % name)

func _pass(detail: String) -> void:
	_log_line("[color=#3a3]PASS[/color] %s" % detail)

func _fail(detail: String) -> void:
	_log_line("[color=#d33]FAIL[/color] %s" % detail)

func _skip(detail: String) -> void:
	_log_line("[color=#c90]SKIPPED[/color] — %s" % detail)

func _warn(detail: String) -> void:
	_log_line("[color=#c90]%s[/color]" % detail)

func _log_line(msg: String) -> void:
	var stamp := Time.get_time_string_from_system()
	log_label.append_text("[%s] %s\n" % [stamp, msg])
	print("[AUTO-TEST] ", msg)

func _on_clear_pressed() -> void:
	log_label.clear()
	_log_line("Log cleared.")

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(log_label.get_parsed_text())
	_log_line("Log copied to clipboard.")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))
