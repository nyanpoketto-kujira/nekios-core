/// nekios_core — protokol bersama ekosistem Nekios.
///
/// Paket Dart murni (tanpa Flutter) yang menjadi kontrak komunikasi
/// antara nekios-remote dan display Nekios (nekios-school, kelak
/// nekios-mosque):
///
/// - Envelope paket + codec yang tidak pernah melempar
///   ([NekiosPacket], [NekiosPacketCodec], [HasilDecodePaket]).
/// - Konstanta protokol v1 ([kNekiosPort], [kNekiosProtocolVersion],
///   [TipePaket]).
/// - Helper WebSocket: [NekiosServer] untuk sisi display dan
///   [NekiosKlien] untuk sisi remote.
///
/// Spesifikasi lengkap ada di `docs/PROTOCOL.md`.
library;

export 'src/codec.dart';
export 'src/klien.dart';
export 'src/konstanta.dart';
export 'src/paket.dart';
export 'src/server.dart';
export 'src/tipe_paket.dart';
