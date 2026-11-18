import 'konstanta.dart';
import 'tipe_paket.dart';

/// Satu paket protokol Nekios: isi sebuah envelope
/// `{ "v": 1, "type": ..., "payload": ... }`.
///
/// Paket ini sengaja tipis — [payload] dibiarkan
/// `Map<String, dynamic>` karena bentuk payload per tipe adalah kontrak
/// pemilik datanya (mis. format jadwal adalah kontrak model
/// nekios-school, bukan milik core). Core hanya mengurus envelope,
/// versi, dan transport.
///
/// Untuk mengubah paket menjadi string JSON (dan sebaliknya) gunakan
/// `NekiosPacketCodec`; [toJson]/[fromJson] di sini adalah representasi
/// map-nya.
class NekiosPacket {
  const NekiosPacket({
    required this.type,
    this.payload,
    this.version = kNekiosProtocolVersion,
  });

  /// Paket `ping` (cek hidup koneksi).
  factory NekiosPacket.ping() => const NekiosPacket(type: TipePaket.ping);

  /// Paket `ack` — perintah [ofType] diterima dan dijalankan.
  factory NekiosPacket.ack({String? ofType}) => NekiosPacket(
        type: TipePaket.ack,
        payload: ofType == null ? null : {'ofType': ofType},
      );

  /// Paket `error` — perintah gagal dijalankan dengan alasan [message].
  factory NekiosPacket.error(String message) => NekiosPacket(
        type: TipePaket.error,
        payload: {'message': message},
      );

  /// Versi protokol envelope (field `v`). Selalu
  /// [kNekiosProtocolVersion] untuk paket yang dibuat paket ini.
  final int version;

  /// Tipe paket (field `type`) — salah satu konstanta di [TipePaket].
  final String type;

  /// Isi paket (field `payload`); null bila tipe tidak membawa isi.
  final Map<String, dynamic>? payload;

  /// Representasi map envelope paket ini.
  Map<String, dynamic> toJson() => {
        'v': version,
        'type': type,
        'payload': payload,
      };

  /// Membaca paket dari map envelope yang SUDAH tervalidasi.
  ///
  /// Lempar [FormatException] bila bentuknya tidak sesuai — pemanggil
  /// yang membaca dari jaringan sebaiknya memakai `NekiosPacketCodec`
  /// yang tidak pernah melempar.
  factory NekiosPacket.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    final type = json['type'];
    final payload = json['payload'];
    if (v is! int) {
      throw const FormatException('field "v" harus int');
    }
    if (type is! String || type.isEmpty) {
      throw const FormatException('field "type" harus string tidak kosong');
    }
    if (payload != null && payload is! Map<String, dynamic>) {
      throw const FormatException('field "payload" harus objek atau null');
    }
    return NekiosPacket(version: v, type: type, payload: payload);
  }

  @override
  String toString() => 'NekiosPacket(v: $version, type: $type, '
      'payload: ${payload == null ? 'null' : 'Map(${payload!.length} field)'})';
}
