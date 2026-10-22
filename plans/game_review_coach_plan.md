# Spesifikasi Arsitektur Game Review & Coach Reviewer

## 1. Komponen Utama

### A. GameReviewService (`src/core/game_review_service.gd`)

- **Fungsi Batch Analysis**: Mengambil rekaman state riwayat pertandingan (`state_history`), mengevaluasi posisi secara berurutan menggunakan engine Stockfish.
- **Klasifikasi Langkah (Move Classification)**:
  - `BRILLIANT` (!!): Pengorbanan perwira bermakna (piece sacrifice) yang mempertahankan keunggulan atau membalikkan situasi.
  - `GREAT` (!): Menemukan satu-satunya langkah terbaik dalam posisi kritis.
  - `BEST` (★): Langkah terbaik pilihan engine (top-1 UCI move).
  - `EXCELLENT`: Langkah hampir setara best move ($\le 25$ centipawn loss).
  - `GOOD`: Langkah solid ($25 - 75$ centipawn loss).
  - `INACCURACY` (?!): Ketidakakuratan minor ($75 - 175$ centipawn loss).
  - `MISTAKE` (?): Kesalahan signifikan ($175 - 350$ centipawn loss).
  - `MISS` (⁇): Melewatkan peluang taktis menang / skakmat.
  - `BLUNDER` (??): Kesalahan fatal ($> 350$ centipawn loss atau membalikkan posisi menang menjadi kalah).
- **Kalkulasi Akurasi (%)**:
  - Model CAPS berbasis win probability sigmoid $P(cp) = \frac{1}{1 + 10^{-cp / 400.0}}$.
  - Rata-rata akurasi per pemain (0.0% - 100.0%).

### B. CoachExplanationGenerator (`src/core/coach_explanation_generator.gd`)

- **Deteksi Motif & Heuristik Taktis**:
  - **Checkmate / Mating Net**: Evaluasi `is_mate` / skakmat paksa sequence.
  - **Winning Queen**: Evaluasi PV engine atau simulasi capture yang merebut menteri lawan via pin, fork, skewer, atau taktik hanging.
  - **Winning Material**: Menghasilkan surplus poin perwira bersih (+1 pawn, +3 piece, +5 rook) atau merebut bidak gantung.
  - **Winning Tempo**: Mengembangkan perwira sambil memberikan ancaman terhadap menteri/raja lawan tanpa membiarkan lawan berinisiatif.
  - **Blunder / Hanging Piece**: Mendeteksi bidak/menteri yang tertinggal tanpa perlindungan (`ThreatDetector`).
  - **Positional Advantage**: Kendali petak pusat, mobilitas perwira, dan pembukaan jalur.

### C. ReviewBadgeOverlay (`src/ui/board/review_badge_overlay.gd`)

- Render badge visual di petak target langkah (`to_sq`) pada [`src/ui/board/chess_board.gd`](src/ui/board/chess_board.gd:12):
  - Badge lingkaran dengan ikon (!!, !, ★, ?, ??) dan palet warna modern ala Chess.com.

### D. GameReviewPanel (`src/ui/hud/game_review_panel.gd` & `.tscn`)

- **Summary Header**:
  - Akurasi Putih vs Hitam.
  - Matriks jumlah langkah per klasifikasi badge.
- **Coach Card**:
  - Avatar ekspresi Coach (Bangga/Senang, Berpikir/Analitis, Khawatir/Blunder).
  - Judul klasifikasi langkah & evaluasi sentipawn (`+3.4`).
  - Teks penjelasan naratif Coach dalam bahasa Indonesia.
  - Tombol aksi:
    - `[👁 Tunjukkan Langkah Terbaik]`: Render panah langkah terbaik + PV variation line.
    - `[🔄 Coba Lagi]`: Mode retry interaktif, mengembalikan papan ke posisi sebelum kesalahan dan menguji tebakan pemain.
- **Navigasi Review**:
  - `[|<]`, `[<]`, `[>]`, `[>|]`.
  - `[⚡ Momen Kunci]`: Langsung melompat ke Inaccuracy/Mistake/Blunder berikutnya.

### E. Integrasi Coordinator di [`src/main.gd`](src/main.gd:968)

- Sambungkan dialog akhir [`src/ui/dialogs/game_over_dialog.gd`](src/ui/dialogs/game_over_dialog.gd:109) ke `start_review()`.
- Pengalihan interaksi papan saat mode review (papan pasif kecuali saat sesi `Retry Move`).
