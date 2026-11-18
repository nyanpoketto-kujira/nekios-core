import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'codec.dart';
import 'konstanta.dart';
import 'paket.dart';

/// Klien WebSocket nekios-remote (sisi pengendali).
///
/// Membungkus `WebSocketChannel`: menyambung ke `ws://host:port`,
/// mengurai bingkai masuk lewat `NekiosPacketCodec`, dan menyediakan
/// stream [packets] untuk balasan display serta [invalidPackets]
/// untuk paket yang gagal decode (untuk log/diagnosis).
///
/// TODO(R2): reconnect otomatis dengan backoff — v1 sengaja manual:
/// pemanggil memanggil [connect] lagi bila koneksi putus (stream
/// [packets] selesai/`done`). Jangan bangun reconnect rumit sebelum
/// pola pemakaian remote jelas.
class NekiosKlien {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _langganan;
  final StreamController<NekiosPacket> _paketMasuk =
      StreamController<NekiosPacket>.broadcast();
  final StreamController<PaketTidakValid> _paketTidakValid =
      StreamController<PaketTidakValid>.broadcast();

  /// Apakah klien sedang tersambung?
  bool get isConnected => _channel != null;

  /// Stream paket valid dari display.
  Stream<NekiosPacket> get packets => _paketMasuk.stream;

  /// Stream paket yang gagal decode dari display (untuk log/diagnosis).
  Stream<PaketTidakValid> get invalidPackets => _paketTidakValid.stream;

  /// Menyambung ke display di [host] (nama host atau alamat IP) pada
  /// [port] (bawaan [kNekiosPort]).
  ///
  /// Selesai (future tuntas) setelah jalur siap dipakai; melempar bila
  /// koneksi gagal dibuat.
  Future<void> connect(String host, {int port = kNekiosPort}) async {
    await close();
    final channel = WebSocketChannel.connect(Uri.parse('ws://$host:$port'));
    _channel = channel;
    await channel.ready;
    _langganan = channel.stream.listen(
      _tanganiData,
      onDone: _tandaiPutus,
      onError: (_) => _tandaiPutus(),
      cancelOnError: true,
    );
  }

  /// Kirim [paket] ke display. No-op diam-diam bila belum tersambung —
  /// cek [isConnected] bila pemanggil perlu kepastian.
  void send(NekiosPacket paket) {
    _channel?.sink.add(NekiosPacketCodec.encode(paket));
  }

  /// Memutus koneksi. Aman dipanggil berulang.
  Future<void> close() async {
    await _langganan?.cancel();
    _langganan = null;
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  void _tandaiPutus() {
    // Stream paket sengaja dibiarkan terbuka agar pemanggil bisa
    // connect ulang tanpa berlangganan ulang; keterputusan diketahui
    // pemanggil dari isConnected yang kembali false.
    _channel = null;
  }

  void _tanganiData(dynamic data) {
    if (data is! String) {
      _paketTidakValid.add(
        const PaketTidakValid(AlasanPaketTidakValid.bukanJson),
      );
      return;
    }
    final hasil = NekiosPacketCodec.decode(data);
    switch (hasil) {
      case PaketValid(:final paket):
        _paketMasuk.add(paket);
      case PaketTidakValid():
        _paketTidakValid.add(hasil);
    }
  }
}
