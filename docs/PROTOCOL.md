# Spesifikasi Protokol Nekios v1

Dokumen ini adalah kontrak resmi komunikasi nekios-remote ↔ display
Nekios. Implementasi acuannya adalah paket `nekios_core` di repo ini;
bila dokumen dan kode berbeda, kode + test yang menang dan dokumen ini
harus diperbarui.

## 1. Transport

- WebSocket (RFC 6455) di jaringan lokal, port baku **8920**
  (`kNekiosPort`), alamat IP display dimasukkan manual di remote
  (keputusan perencanaan 2026-11-18).
- Display adalah **server**, remote adalah **klien**.
- Satu bingkai teks WebSocket = satu paket JSON. Bingkai biner tidak
  dipakai dan diperlakukan sebagai paket tidak valid.
- v1 **tanpa autentikasi/PIN** — diasumsikan berjalan di LAN terpercaya
  (panggung pameran). Ini keputusan sadar untuk v1, bukan kelalaian;
  menaikkannya dibahas bila protokol naik versi.

## 2. Envelope

Setiap paket adalah objek JSON:

```json
{ "v": 1, "type": "mading.set", "payload": { "text": "..." } }
```

| Field | Tipe | Wajib | Keterangan |
| --- | --- | --- | --- |
| `v` | int | ya | Versi protokol. v1 selalu `1`. |
| `type` | string | ya | Tipe paket (§3), tidak boleh kosong. |
| `payload` | objek / null | tidak | Isi per tipe; boleh tidak ada (= null). Tidak boleh berupa array/skalar. |

## 3. Tipe paket

### 3.1 Perintah — remote → display

| Tipe | Payload | Makna |
| --- | --- | --- |
| `schedule.replace` | JSON jadwal lengkap | Ganti seluruh jadwal display. Format payload adalah kontrak model nekios-school (struktur file `jadwal-tkj.json`), bukan kontrak core. |
| `mading.set` | `{ "text": String }` | Ubah teks mading yang sedang tayang. |
| `clock.simulate` | `{ "at": String ISO-8601 }` | Display menampilkan keadaan seolah jam menunjukkan `at`. |
| `clock.clear` | — | Akhiri simulasi; kembali ke jam sistem. |
| `logo.set` | `{ "imageBase64": String }` | Pasang/ganti logo display (gambar ter-encode base64). |
| `ping` | — | Cek hidup; display membalas `ack` dan/atau `state.snapshot`. |
| `audio.konfigurasi` | `{ "belAktif": bool }` | Atur saklar bel sekolah di display (tersimpan persisten di display). Display membalas `ack` + `state.snapshot`. |
| `audio.tes` | — | Display memutar pengumuman bel untuk slot yang sedang berjalan (uji suara). Selalu diputar, juga saat `belAktif` nonaktif. Display membalas `ack`. |

### 3.2 Balasan — display → remote

| Tipe | Payload | Makna |
| --- | --- | --- |
| `state.snapshot` | objek keadaan | Potret keadaan display (status, jam efektif, mading, simulasi aktif). Bentuk rinci dimiliki nekios-school sebagai pemilik keadaan. Sejak fitur bel (2026-11-19) snapshot display sekolah juga memuat `belAktif` (bool) dan `belTerakhir` (`{ "berkas": String, "pada": String ISO-8601 }` atau null — pengumuman bel terakhir yang diputar beserta waktu efektifnya). |
| `ack` | `{ "ofType": String }` (opsional) | Perintah diterima & dijalankan. |
| `error` | `{ "message": String }` | Perintah gagal dijalankan; `message` untuk log/tampilan. |

## 4. Aturan versi & paket tak dikenal

- Penerima **wajib** menolak (tanpa memutus koneksi) paket yang:
  bukan JSON valid, bukan objek, `v` hilang/bukan int, `v` ≠ versi yang
  didukung, `type` hilang/kosong, `type` tidak dikenal, atau `payload`
  bukan objek/null.
- Penolakan berarti: paket **diabaikan + dicatat log** dengan alasannya
  (`AlasanPaketTidakValid` di codec). Penerima tidak mengirim `error`
  untuk paket yang bahkan tidak bisa dibaca typenya.
- Tipe baru hanya boleh ditambah lewat perubahan protokol yang
  disepakati lintas repo (ADR). Bila tipe baru mengubah makna paket
  lama atau envelope, naikkan `v`.
- Arah paket tidak ditegakkan codec: paket `ack` yang datang ke display
  tetap *valid secara bentuk*; penegakan arah adalah tanggung jawab
  pemanggil (server/klien).

## 5. Pola interaksi yang diharapkan

1. Remote menyambung → kirim `ping` → display membalas `ack` +
   `state.snapshot`. Remote menampilkan keadaan display dari snapshot.
2. Setiap perintah remote dijawab display dengan `ack` (berhasil) atau
   `error` (gagal, mis. jadwal tidak lolos validasi), diikuti
   `state.snapshot` terbaru bila perintah mengubah keadaan.
3. Simulasi jam adalah keadaan display, bukan perintah sekali lewat:
   setelah `clock.simulate`, snapshot melaporkan simulasi aktif sampai
   `clock.clear` diterima atau display dimulai ulang.
