import 'dart:convert';

import 'konstanta.dart';
import 'paket.dart';
import 'tipe_paket.dart';

/// Alasan sebuah paket dinyatakan tidak valid oleh `NekiosPacketCodec`.
enum AlasanPaketTidakValid {
  /// Teks bukan JSON yang valid, atau bingkai bukan teks sama sekali.
  bukanJson('teks bukan JSON yang valid'),

  /// JSON valid tetapi bukan objek di tingkat atas.
  bukanObjek('JSON tingkat atas bukan objek'),

  /// Field `v` tidak ada atau bukan bilangan bulat.
  versiHilang('field "v" tidak ada atau bukan int'),

  /// Field `v` ada tetapi bukan versi yang didukung paket ini.
  versiTidakDidukung('versi protokol tidak didukung'),

  /// Field `type` tidak ada, bukan string, atau string kosong.
  tipeHilang('field "type" tidak ada atau bukan string tidak kosong'),

  /// Field `type` ada tetapi tidak dikenal protokol v1.
  tipeTidakDikenal('tipe paket tidak dikenal protokol v1'),

  /// Field `payload` ada tetapi bukan objek JSON dan bukan null.
  payloadTidakValid('field "payload" harus objek JSON atau null');

  const AlasanPaketTidakValid(this.deskripsi);

  /// Penjelasan singkat alasan ini, untuk log dan pesan error.
  final String deskripsi;
}

/// Hasil decode sebuah paket mentah oleh `NekiosPacketCodec`.
///
/// Codec TIDAK PERNAH melempar untuk masukan dari jaringan: paket rusak,
/// versi asing, dan tipe tak dikenal semuanya kembali sebagai
/// [PaketTidakValid] agar pemanggil bisa membedakan dan memutuskan
/// (abaikan + log adalah perilaku yang dianjurkan).
sealed class HasilDecodePaket {
  const HasilDecodePaket();
}

/// Decode berhasil — paket valid dan dikenal protokol v1.
final class PaketValid extends HasilDecodePaket {
  const PaketValid(this.paket);

  /// Paket hasil decode.
  final NekiosPacket paket;

  @override
  String toString() => 'PaketValid($paket)';
}

/// Decode gagal — paket tidak valid; lihat [alasan].
final class PaketTidakValid extends HasilDecodePaket {
  const PaketTidakValid(
    this.alasan, {
    this.typeMentah,
    this.versiMentah,
  });

  /// Kategori kegagalan.
  final AlasanPaketTidakValid alasan;

  /// Nilai field `type` mentah bila sempat terbaca (untuk log).
  final String? typeMentah;

  /// Nilai field `v` mentah bila sempat terbaca (untuk log).
  final int? versiMentah;

  @override
  String toString() => 'PaketTidakValid(${alasan.name}: ${alasan.deskripsi}'
      '${typeMentah != null ? ', type: $typeMentah' : ''}'
      '${versiMentah != null ? ', v: $versiMentah' : ''})';
}

/// Encode/decode paket Nekios ke/dari string JSON untuk transport
/// WebSocket (satu bingkai teks = satu paket).
abstract final class NekiosPacketCodec {
  /// Mengubah [paket] menjadi string JSON envelope.
  static String encode(NekiosPacket paket) => jsonEncode(paket.toJson());

  /// Membaca paket dari string JSON mentah.
  ///
  /// Tidak pernah melempar: semua kegagalan (JSON rusak, bentuk salah,
  /// versi tidak didukung, tipe tidak dikenal, payload salah bentuk)
  /// dikembalikan sebagai [PaketTidakValid] dengan alasannya.
  static HasilDecodePaket decode(String mentah) {
    final Object? json;
    try {
      json = jsonDecode(mentah);
    } on FormatException {
      return const PaketTidakValid(AlasanPaketTidakValid.bukanJson);
    }
    if (json is! Map<String, dynamic>) {
      return const PaketTidakValid(AlasanPaketTidakValid.bukanObjek);
    }

    final vMentah = json['v'];
    final typeMentah = json['type'];
    final typeLog = typeMentah is String ? typeMentah : null;

    if (vMentah is! int) {
      return PaketTidakValid(
        AlasanPaketTidakValid.versiHilang,
        typeMentah: typeLog,
      );
    }
    if (vMentah != kNekiosProtocolVersion) {
      return PaketTidakValid(
        AlasanPaketTidakValid.versiTidakDidukung,
        typeMentah: typeLog,
        versiMentah: vMentah,
      );
    }
    if (typeMentah is! String || typeMentah.isEmpty) {
      return PaketTidakValid(
        AlasanPaketTidakValid.tipeHilang,
        versiMentah: vMentah,
      );
    }
    if (!TipePaket.dikenal(typeMentah)) {
      return PaketTidakValid(
        AlasanPaketTidakValid.tipeTidakDikenal,
        typeMentah: typeMentah,
        versiMentah: vMentah,
      );
    }
    final payload = json['payload'];
    if (payload != null && payload is! Map<String, dynamic>) {
      return PaketTidakValid(
        AlasanPaketTidakValid.payloadTidakValid,
        typeMentah: typeMentah,
        versiMentah: vMentah,
      );
    }
    return PaketValid(
      NekiosPacket(version: vMentah, type: typeMentah, payload: payload),
    );
  }
}
