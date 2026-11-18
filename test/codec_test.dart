import 'dart:convert';

import 'package:nekios_core/nekios_core.dart';
import 'package:test/test.dart';

void main() {
  group('NekiosPacketCodec.encode', () {
    test('menghasilkan string JSON envelope yang utuh', () {
      final mentah = NekiosPacketCodec.encode(
        const NekiosPacket(
          type: TipePaket.clockClear,
        ),
      );
      expect(jsonDecode(mentah), {
        'v': 1,
        'type': 'clock.clear',
        'payload': null,
      });
    });
  });

  group('NekiosPacketCodec.decode — paket valid', () {
    test('round-trip encode → decode mempertahankan isi paket', () {
      const asli = NekiosPacket(
        type: TipePaket.scheduleReplace,
        payload: {
          'meta': {'sekolah': 'SMKN 1 Ukui'},
          'kelas': [
            {'id': 'X-TKJ-A'},
          ],
        },
      );
      final hasil = NekiosPacketCodec.decode(NekiosPacketCodec.encode(asli));
      expect(hasil, isA<PaketValid>());
      final paket = (hasil as PaketValid).paket;
      expect(paket.version, asli.version);
      expect(paket.type, asli.type);
      expect(paket.payload, asli.payload);
    });

    test('payload boleh tidak ada sama sekali', () {
      final hasil = NekiosPacketCodec.decode('{"v":1,"type":"ping"}');
      expect(hasil, isA<PaketValid>());
      expect((hasil as PaketValid).paket.payload, isNull);
    });

    test('semua tipe v1 yang dikenal lolos decode', () {
      for (final type in TipePaket.semua) {
        final hasil = NekiosPacketCodec.decode(
          jsonEncode({'v': 1, 'type': type, 'payload': null}),
        );
        expect(hasil, isA<PaketValid>(), reason: 'tipe $type harus valid');
      }
    });
  });

  group('NekiosPacketCodec.decode — paket tidak valid (tidak pernah throw)',
      () {
    PaketTidakValid decodeTidakValid(String mentah) {
      final hasil = NekiosPacketCodec.decode(mentah);
      expect(hasil, isA<PaketTidakValid>(), reason: 'masukan: $mentah');
      return hasil as PaketTidakValid;
    }

    test('teks bukan JSON → bukanJson', () {
      expect(
        decodeTidakValid('halo ini bukan json').alasan,
        AlasanPaketTidakValid.bukanJson,
      );
      expect(
        decodeTidakValid('').alasan,
        AlasanPaketTidakValid.bukanJson,
      );
    });

    test('JSON bukan objek → bukanObjek', () {
      expect(
        decodeTidakValid('[1,2,3]').alasan,
        AlasanPaketTidakValid.bukanObjek,
      );
      expect(
        decodeTidakValid('"ping"').alasan,
        AlasanPaketTidakValid.bukanObjek,
      );
      expect(
        decodeTidakValid('42').alasan,
        AlasanPaketTidakValid.bukanObjek,
      );
    });

    test('field v hilang / bukan int → versiHilang', () {
      expect(
        decodeTidakValid('{"type":"ping"}').alasan,
        AlasanPaketTidakValid.versiHilang,
      );
      expect(
        decodeTidakValid('{"v":"1","type":"ping"}').alasan,
        AlasanPaketTidakValid.versiHilang,
      );
    });

    test('versi selain 1 → versiTidakDidukung, versi mentah tercatat', () {
      final hasil = decodeTidakValid('{"v":2,"type":"ping"}');
      expect(hasil.alasan, AlasanPaketTidakValid.versiTidakDidukung);
      expect(hasil.versiMentah, 2);
    });

    test('field type hilang / kosong → tipeHilang', () {
      expect(
        decodeTidakValid('{"v":1}').alasan,
        AlasanPaketTidakValid.tipeHilang,
      );
      expect(
        decodeTidakValid('{"v":1,"type":""}').alasan,
        AlasanPaketTidakValid.tipeHilang,
      );
      expect(
        decodeTidakValid('{"v":1,"type":7}').alasan,
        AlasanPaketTidakValid.tipeHilang,
      );
    });

    test('tipe tak dikenal → tipeTidakDikenal, tipe mentah tercatat', () {
      final hasil = decodeTidakValid('{"v":1,"type":"jadwal.ganti"}');
      expect(hasil.alasan, AlasanPaketTidakValid.tipeTidakDikenal);
      expect(hasil.typeMentah, 'jadwal.ganti');
    });

    test('payload bukan objek → payloadTidakValid', () {
      expect(
        decodeTidakValid('{"v":1,"type":"ping","payload":[1]}').alasan,
        AlasanPaketTidakValid.payloadTidakValid,
      );
      expect(
        decodeTidakValid('{"v":1,"type":"ping","payload":"teks"}').alasan,
        AlasanPaketTidakValid.payloadTidakValid,
      );
    });
  });
}
