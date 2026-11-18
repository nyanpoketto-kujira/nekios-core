/// Konstanta protokol Nekios versi 1.
///
/// Satu-satunya tempat angka-angka protokol didefinisikan; semua repo
/// ekosistem (nekios-school, nekios-remote, kelak nekios-mosque) wajib
/// memakai konstanta dari sini, bukan menulis ulang literalnya.
library;

/// Versi protokol yang didukung paket ini.
///
/// Tercantum di field `v` setiap envelope. Paket dengan versi selain ini
/// ditolak codec sebagai tidak didukung (lihat `NekiosPacketCodec`).
const int kNekiosProtocolVersion = 1;

/// Port WebSocket baku antara nekios-remote dan display Nekios.
///
/// Diputuskan nyanpo pada perencanaan nekios-remote (2026-11-18):
/// port 8920 + alamat IP manual, tanpa PIN untuk v1.
const int kNekiosPort = 8920;
