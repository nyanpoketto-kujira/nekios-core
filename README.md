# nekios-core

Paket protokol bersama **ekosistem Nekios** — kontrak komunikasi antara
**nekios-remote** (aplikasi pengendali di HP) dan **display Nekios**
(nekios-school untuk TV sekolah, kelak nekios-mosque).

Dart murni tanpa Flutter: paket ini bisa dipakai aplikasi Flutter maupun
program CLI Dart. Ia hanya mengurus *envelope, versi, dan transport* —
bentuk data di dalam payload tetap kontrak repo pemiliknya (mis. format
jadwal adalah kontrak model nekios-school).

## Isi paket

| Bagian | Isi |
| --- | --- |
| `NekiosPacket` | Satu paket = satu envelope `{v, type, payload}` + factory `ping`/`ack`/`error`. |
| `NekiosPacketCodec` | Encode/decode string JSON. **Tidak pernah melempar**: paket rusak/asing kembali sebagai `PaketTidakValid` dengan `AlasanPaketTidakValid`. |
| `TipePaket` | Konstanta semua tipe paket v1 + himpunan arah `perintah`/`balasan`. |
| `kNekiosPort` | Port WebSocket baku: **8920**. |
| `kNekiosProtocolVersion` | Versi protokol: **1**. |
| `NekiosServer` | Server WebSocket (dart:io) untuk sisi display; stream paket masuk membawa fungsi `balas` per klien. |
| `NekiosKlien` | Klien WebSocket (`web_socket_channel`) untuk sisi remote. |

## Tipe paket v1

Perintah (remote → display):

| Tipe | Guna |
| --- | --- |
| `schedule.replace` | Ganti seluruh jadwal (payload = JSON jadwal lengkap). |
| `mading.set` | Ubah teks mading (`{"text": ...}`). |
| `clock.simulate` | Simulasikan jam display (`{"at": ISO-8601}`). |
| `clock.clear` | Akhiri simulasi jam. |
| `logo.set` | Pasang/ganti logo (`{"imageBase64": ...}`). |
| `ping` | Cek hidup koneksi. |

Balasan (display → remote): `state.snapshot`, `ack`, `error`.

Spesifikasi lengkap: [docs/PROTOCOL.md](docs/PROTOCOL.md).

## Contoh envelope

```json
{
  "v": 1,
  "type": "mading.set",
  "payload": { "text": "Pameran dibuka pukul 08.00" }
}
```

## Contoh pakai

Display (server):

```dart
final server = NekiosServer(); // port 8920
await server.start();
server.packets.listen((masuk) {
  if (masuk.paket.type == TipePaket.ping) {
    masuk.balas(NekiosPacket.ack(ofType: TipePaket.ping));
  }
});
```

Remote (klien):

```dart
final klien = NekiosKlien();
await klien.connect('192.168.1.20'); // IP display, port baku 8920
klien.send(NekiosPacket.ping());
```

## Status

Fase R0 ekosistem Nekios (2026-11-18): protokol v1 + helper WebSocket
minimal, teruji unit + integrasi localhost. Reconnect otomatis klien
sengaja ditunda (TODO terdokumentasi di `NekiosKlien`) sampai pola
pemakaian remote jelas di Fase R2.
