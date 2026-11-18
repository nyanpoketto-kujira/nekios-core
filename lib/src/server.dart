import 'dart:async';
import 'dart:io';

import 'codec.dart';
import 'konstanta.dart';
import 'paket.dart';

/// Paket valid yang diterima [NekiosServer] dari seorang klien,
/// lengkap dengan cara membalas ke klien yang sama.
///
/// Balasan per-klien penting untuk pola perintah→jawaban protokol
/// (mis. `ping` dibalas `ack`/`state.snapshot` hanya ke peminta),
/// jadi stream server tidak mengantar paket polos melainkan bungkus
/// ini.
class PaketMasuk {
  const PaketMasuk(this.paket, {required this.balas});

  /// Paket yang diterima (sudah lolos codec).
  final NekiosPacket paket;

  /// Kirim [jawaban] hanya ke klien pengirim paket ini.
  final void Function(NekiosPacket jawaban) balas;

  @override
  String toString() => 'PaketMasuk($paket)';
}

/// Server WebSocket display Nekios (sisi yang dikendalikan).
///
/// Membungkus `HttpServer` + `WebSocketTransformer` dari dart:io:
/// menerima koneksi, mengurai setiap bingkai teks lewat
/// `NekiosPacketCodec`, dan meneruskan paket valid ke stream [packets].
/// Paket rusak tidak memutus koneksi — ia diteruskan ke stream
/// [invalidPackets] agar pemanggil cukup mencatat log.
///
/// Dipakai nekios-school (Fase R1) sebagai jantung
/// `CoreWebSocketSource`. Satu server melayani banyak klien; v1
/// protokol mengasumsikan satu remote aktif pada satu waktu, tetapi
/// server tidak menegakkan batas itu.
class NekiosServer {
  NekiosServer({this.port = kNekiosPort});

  /// Port yang diminta saat [start]. Isi 0 agar sistem memilih port
  /// kosong (berguna untuk test); port hasil ikatan yang sebenarnya
  /// dibaca lewat [boundPort].
  final int port;

  HttpServer? _httpServer;
  final Set<WebSocket> _klien = {};
  final StreamController<PaketMasuk> _paketMasuk =
      StreamController<PaketMasuk>.broadcast();
  final StreamController<PaketTidakValid> _paketTidakValid =
      StreamController<PaketTidakValid>.broadcast();

  /// Apakah server sedang berjalan?
  bool get isRunning => _httpServer != null;

  /// Port tempat server benar-benar terikat (setelah [start]);
  /// sebelum start, mengembalikan port yang diminta.
  int get boundPort => _httpServer?.port ?? port;

  /// Jumlah klien yang sedang terhubung.
  int get clientCount => _klien.length;

  /// Stream paket valid dari semua klien.
  Stream<PaketMasuk> get packets => _paketMasuk.stream;

  /// Stream paket yang gagal decode dari klien (untuk log/diagnosis).
  Stream<PaketTidakValid> get invalidPackets => _paketTidakValid.stream;

  /// Menyalakan server. Memanggil saat sudah berjalan adalah no-op.
  Future<void> start() async {
    if (_httpServer != null) return;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _httpServer = server;
    server.listen(_tanganiRequest);
  }

  /// Mematikan server dan memutus semua klien.
  Future<void> stop() async {
    final server = _httpServer;
    _httpServer = null;
    for (final socket in _klien.toList()) {
      await socket.close();
    }
    _klien.clear();
    await server?.close(force: true);
  }

  /// Kirim [paket] ke SEMUA klien yang terhubung.
  void broadcast(NekiosPacket paket) {
    final mentah = NekiosPacketCodec.encode(paket);
    for (final socket in _klien) {
      socket.add(mentah);
    }
  }

  Future<void> _tanganiRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    _klien.add(socket);
    socket.listen(
      (data) => _tanganiData(socket, data),
      onDone: () => _klien.remove(socket),
      onError: (_) => _klien.remove(socket),
      cancelOnError: true,
    );
  }

  void _tanganiData(WebSocket socket, Object? data) {
    if (data is! String) {
      _paketTidakValid.add(
        const PaketTidakValid(AlasanPaketTidakValid.bukanJson),
      );
      return;
    }
    final hasil = NekiosPacketCodec.decode(data);
    switch (hasil) {
      case PaketValid(:final paket):
        _paketMasuk.add(
          PaketMasuk(
            paket,
            balas: (jawaban) =>
                socket.add(NekiosPacketCodec.encode(jawaban)),
          ),
        );
      case PaketTidakValid():
        _paketTidakValid.add(hasil);
    }
  }
}
