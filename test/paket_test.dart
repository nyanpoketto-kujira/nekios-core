import 'package:nekios_core/nekios_core.dart';
import 'package:test/test.dart';

void main() {
  group('konstanta protokol', () {
    test('port baku 8920 dan versi protokol 1 (keputusan terkunci)', () {
      expect(kNekiosPort, 8920);
      expect(kNekiosProtocolVersion, 1);
    });
  });

  group('TipePaket', () {
    test('perintah dan balasan tidak tumpang tindih', () {
      expect(TipePaket.perintah.intersection(TipePaket.balasan), isEmpty);
    });

    test('semua berisi gabungan perintah + balasan', () {
      expect(
        TipePaket.semua,
        {...TipePaket.perintah, ...TipePaket.balasan},
      );
      expect(TipePaket.semua, hasLength(9));
    });

    test('dikenal() mengenali tipe v1 dan menolak selainnya', () {
      expect(TipePaket.dikenal(TipePaket.scheduleReplace), isTrue);
      expect(TipePaket.dikenal(TipePaket.stateSnapshot), isTrue);
      expect(TipePaket.dikenal('jadwal.ganti'), isFalse);
      expect(TipePaket.dikenal(''), isFalse);
    });
  });

  group('NekiosPacket', () {
    test('toJson menghasilkan envelope v/type/payload', () {
      const paket = NekiosPacket(
        type: TipePaket.madingSet,
        payload: {'text': 'Selamat datang'},
      );
      expect(paket.toJson(), {
        'v': 1,
        'type': 'mading.set',
        'payload': {'text': 'Selamat datang'},
      });
    });

    test('fromJson membaca envelope yang valid', () {
      final paket = NekiosPacket.fromJson({
        'v': 1,
        'type': 'clock.simulate',
        'payload': {'at': '2026-11-17T12:20:24'},
      });
      expect(paket.version, 1);
      expect(paket.type, TipePaket.clockSimulate);
      expect(paket.payload, {'at': '2026-11-17T12:20:24'});
    });

    test('fromJson melempar FormatException untuk bentuk yang salah', () {
      expect(
        () => NekiosPacket.fromJson({'type': 'ping', 'payload': null}),
        throwsFormatException,
      );
      expect(
        () => NekiosPacket.fromJson({'v': 1, 'type': '', 'payload': null}),
        throwsFormatException,
      );
      expect(
        () => NekiosPacket.fromJson({'v': 1, 'type': 'ping', 'payload': 42}),
        throwsFormatException,
      );
    });

    test('factory ping/ack/error membentuk tipe yang benar', () {
      expect(NekiosPacket.ping().type, TipePaket.ping);
      expect(NekiosPacket.ping().payload, isNull);

      final ack = NekiosPacket.ack(ofType: TipePaket.madingSet);
      expect(ack.type, TipePaket.ack);
      expect(ack.payload, {'ofType': 'mading.set'});

      final error = NekiosPacket.error('jadwal tidak valid');
      expect(error.type, TipePaket.error);
      expect(error.payload, {'message': 'jadwal tidak valid'});
    });
  });
}
