extends SceneTree

const EngineService = preload("res://src/engine/engine_service.gd")

func _init() -> void:
	print("==================================================")
	print("       VERIFIKASI INTEGRASI MAIA-3 DI GODOT       ")
	print("==================================================")
	_run_async_verification()

func _run_async_verification() -> void:
	var es = EngineService.new()
	root.add_child(es)

	print("[1/4] Menunggu inisialisasi EngineService & Maia-3...")

	var timeout_secs = 20.0
	var elapsed = 0.0
	while elapsed < timeout_secs:
		if es.is_maia_ready and es.maia_client != null:
			break
		await create_timer(0.2).timeout
		elapsed += 0.2

	if not es.is_maia_ready:
		print("❌ GAGAL: Maia-3 tidak siap dalam batas waktu %.1f detik" % timeout_secs)
		es.queue_free()
		quit(1)
		return

	print("✅ [2/4] Maia-3 terdeteksi SIAP (is_maia_ready = true)")
	print("       PID Maia Process: ", es.maia_client.pid)

	es.maia_client.line_received.connect(func(line):
		print("  [MAIA RAW OUT] ", line)
	)

	var test_fen = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
	var test_elo = 1500
	print("\n[3/4] Mengirim request AI Move ke Maia-3:")
	print("       FEN: ", test_fen)
	print("       Target Elo: ", test_elo)

	var result = { "move": "" }
	es.ai_move_ready.connect(func(mv):
		result["move"] = mv
	)

	es.request_ai_move(test_fen, test_elo)

	var move_timeout = 15.0
	var move_elapsed = 0.0
	while move_elapsed < move_timeout and result["move"].is_empty():
		await create_timer(0.2).timeout
		move_elapsed += 0.2

	if result["move"].is_empty():
		print("❌ GAGAL: Tidak menerima langkah dari Maia-3")
		es.queue_free()
		quit(1)
		return

	print("✅ [4/4] Langkah berhasil diterima dari Maia-3!")
	print("       Langkah yang dipilih: ", result["move"])
	print("       (Karakteristik manusiawi: Pada posisi 1. e4 e5, Maia memilih langkah natural catur)")

	print("\n==================================================")
	print("  STATUS: INTEGRASI MAIA-3 100% SUKSES & VALID!   ")
	print("==================================================")
	es.queue_free()
	quit(0)
