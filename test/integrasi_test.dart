import 'dart:io';

import 'package:nekios_core/nekios_core.dart';
import 'package:test/test.dart';

void main() {
  group('integrasi server ↔ klien di localhost', () {
    late NekiosServer server;
    late NekiosKlien klien;

    setUp(() async {
      // Port 0 = sistem memilih port kosong; port asli dibaca dari
      // server.boundPort agar test tidak pernah bentrok port.
      server = NekiosServer(port: 0);
      await server.start();
      klien = NekiosKlien();
    });

    tearDown(() async {
      await klien.close();
      await server.stop();
    });

    test('ping dari klien sampai ke server dan ack kembali ke klien',
        () async {
      expect(server.isRunning, isTrue);
      expect(server.boundPort, greaterThan(0));

      // Display tiruan: ping dibalas ack + snapshot keadaan.
      final langganan = server.packets.listen((masuk) {
        if (masuk.paket.type == TipePaket.ping) {
          masuk.balas(NekiosPacket.ack(ofType: TipePaket.ping));
          masuk.balas(
            const NekiosPacket(
              type: TipePaket.stateSnapshot,
              payload: {'status': 'pelajaran', 'simulasiAktif': false},
            ),
          );
        }
      });
      addTearDown(langganan.cancel);

      await klien.connect('127.0.0.1', port: server.boundPort);
      expect(klien.isConnected, isTrue);
      expect(server.clientCount, 1);

      final balasan = klien.packets.take(2).toList();
      klien.send(NekiosPacket.ping());
      final diterima = await balasan.timeout(const Duration(seconds: 5));

      expect(diterima.map((p) => p.type), [
        TipePaket.ack,
        TipePaket.stateSnapshot,
      ]);
      expect(diterima.first.payload, {'ofType': 'ping'});
      expect(diterima.last.payload?['status'], 'pelajaran');
    });

    test('perintah mading.set dari klien terbaca utuh di server', () async {
      final diterima = server.packets.first;
      await klien.connect('127.0.0.1', port: server.boundPort);
      klien.send(
        const NekiosPacket(
          type: TipePaket.madingSet,
          payload: {'text': 'Pameran dibuka pukul 08.00'},
        ),
      );
      final masuk = await diterima.timeout(const Duration(seconds: 5));
      expect(masuk.paket.type, TipePaket.madingSet);
      expect(masuk.paket.payload, {'text': 'Pameran dibuka pukul 08.00'});
    });

    test('broadcast server sampai ke klien yang terhubung', () async {
      final diterima = klien.packets.first;
      await klien.connect('127.0.0.1', port: server.boundPort);
      server.broadcast(
        const NekiosPacket(
          type: TipePaket.stateSnapshot,
          payload: {'status': 'isoma'},
        ),
      );
      final paket = await diterima.timeout(const Duration(seconds: 5));
      expect(paket.type, TipePaket.stateSnapshot);
      expect(paket.payload, {'status': 'isoma'});
    });

    test('bingkai rusak dari klien asing masuk stream invalidPackets, '
        'koneksi tidak putus', () async {
      final tidakValid = server.invalidPackets.first;
      final mentah = await WebSocket.connect(
        'ws://127.0.0.1:${server.boundPort}',
      );
      addTearDown(() => mentah.close());
      mentah.add('ini bukan paket nekios');
      final hasil = await tidakValid.timeout(const Duration(seconds: 5));
      expect(hasil.alasan, AlasanPaketTidakValid.bukanJson);
      expect(server.clientCount, 1);
    });
  });
}
