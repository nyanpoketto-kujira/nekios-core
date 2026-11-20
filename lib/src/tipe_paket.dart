/// Konstanta tipe paket protokol Nekios v1.
///
/// Tipe paket adalah string di field `type` envelope. Daftar ini adalah
/// kontrak bersama: menambah tipe baru berarti mengubah protokol dan
/// menaikkannya lewat pembahasan ADR, bukan menambah string diam-diam
/// di satu repo saja.
///
/// Arah:
/// - [perintah] — dikirim remote → display.
/// - [balasan] — dikirim display → remote.
///
/// Codec menerima semua tipe yang dikenal di [semua] tanpa membedakan
/// arah; penegakan arah adalah urusan pemanggil (server/client).
abstract final class TipePaket {
  // --- Perintah: remote → display -------------------------------------------

  /// Ganti seluruh jadwal display. Payload = JSON jadwal lengkap
  /// (format kontrak model nekios-school).
  static const String scheduleReplace = 'schedule.replace';

  /// Ubah teks mading yang sedang tayang. Payload: `{ "text": String }`.
  static const String madingSet = 'mading.set';

  /// Simulasikan jam display ke momen tertentu (demo semua status tanpa
  /// menunggu waktu asli). Payload: `{ "at": String ISO-8601 }`.
  static const String clockSimulate = 'clock.simulate';

  /// Akhiri simulasi jam; display kembali ke jam sistem.
  static const String clockClear = 'clock.clear';

  /// Pasang/ganti logo display. Payload: `{ "imageBase64": String }`.
  static const String logoSet = 'logo.set';

  /// Cek hidup koneksi. Display membalas `ack` dan/atau `state.snapshot`.
  static const String ping = 'ping';

  /// Atur saklar bel sekolah di display. Payload: `{ "belAktif": bool }`.
  /// Display membalas `ack` + `state.snapshot` dengan keadaan terbaru.
  static const String audioKonfigurasi = 'audio.konfigurasi';

  /// Minta display memutar pengumuman bel untuk slot yang sedang berjalan
  /// (uji suara dari remote). Payload: `{}`. Selalu diputar, juga saat
  /// belAktif nonaktif — ini uji manual yang disengaja.
  static const String audioTes = 'audio.tes';

  // --- Balasan: display → remote --------------------------------------------

  /// Potret keadaan display saat ini (status, jam efektif, teks mading,
  /// apakah simulasi aktif). Bentuk payload dimiliki nekios-school
  /// sebagai pemilik keadaan tampilan.
  static const String stateSnapshot = 'state.snapshot';

  /// Perintah diterima dan dijalankan. Payload opsional:
  /// `{ "ofType": String }` menunjuk tipe perintah yang diakui.
  static const String ack = 'ack';

  /// Perintah gagal dijalankan. Payload: `{ "message": String }`.
  static const String error = 'error';

  /// Semua tipe perintah (remote → display).
  static const Set<String> perintah = {
    scheduleReplace,
    madingSet,
    clockSimulate,
    clockClear,
    logoSet,
    ping,
    audioKonfigurasi,
    audioTes,
  };

  /// Semua tipe balasan (display → remote).
  static const Set<String> balasan = {
    stateSnapshot,
    ack,
    error,
  };

  /// Semua tipe paket yang dikenal protokol v1.
  static const Set<String> semua = {...perintah, ...balasan};

  /// Apakah [type] dikenal protokol v1?
  static bool dikenal(String type) => semua.contains(type);
}
