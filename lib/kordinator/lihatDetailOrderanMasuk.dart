import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://192.168.1.6:8000/api';

class DetailOrderKoordinatorPage extends StatefulWidget {
  final int orderId;

  const DetailOrderKoordinatorPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<DetailOrderKoordinatorPage> createState() =>
      _DetailOrderKoordinatorPageState();
}

class _DetailOrderKoordinatorPageState
    extends State<DetailOrderKoordinatorPage> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _order;

  // ====== PERAWAT (ANAK KOORDINATOR) ======
  bool _isLoadingPerawat = false;
  bool _isAssigningPerawat = false;
  List<Map<String, dynamic>> _perawats = [];
  int? _selectedPerawatId;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _fetchDetail(internalCall: true),
        _fetchPerawatList(internalCall: true),
      ]);

      // set default selected perawat dari data order (kalau sudah ada)
      final perawatId = _order?['perawat_id'];
      if (perawatId != null) {
        if (perawatId is int) {
          _selectedPerawatId = perawatId;
        } else {
          _selectedPerawatId = int.tryParse(perawatId.toString());
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan saat memuat data: $e';
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchDetail({bool internalCall = false}) async {
    if (!internalCall) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Token tidak ditemukan. Silakan login sebagai koordinator.';
      });
      return;
    }

    try {
      final uri =
          Uri.parse('$kBaseUrl/koordinator/order-layanan/${widget.orderId}');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        if (!success) {
          setState(() {
            _isLoading = false;
            _error = decoded['message']?.toString() ??
                'Gagal memuat detail order.';
          });
          return;
        }

        setState(() {
          _order = decoded['data'] as Map<String, dynamic>;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _error = 'Order tidak ditemukan (404).';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login koordinator berakhir. Silakan login ulang.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error =
              'Gagal memuat detail. Kode: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _fetchPerawatList({bool internalCall = false}) async {
    if (!internalCall) {
      setState(() {
        _isLoadingPerawat = true;
      });
    }

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoadingPerawat = false;
      });
      return;
    }

    try {
      // endpoint: GET /api/koordinator/perawat-list
      final uri = Uri.parse('$kBaseUrl/koordinator/perawat-list');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = decoded['data'] ?? [];

        final list = data
            .map<Map<String, dynamic>>(
              (e) => (e as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              ),
            )
            .toList();

        setState(() {
          _perawats = list;
          _isLoadingPerawat = false;
        });
      } else {
        setState(() {
          _isLoadingPerawat = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPerawat = false;
      });
    }
  }

  Future<void> _assignPerawat() async {
    if (_selectedPerawatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih perawat terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() {
      _isAssigningPerawat = true;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isAssigningPerawat = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    try {
      // endpoint: POST /api/koordinator/order-layanan/{id}/assign-perawat
      final uri = Uri.parse(
          '$kBaseUrl/koordinator/order-layanan/${widget.orderId}/assign-perawat');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'perawat_id': _selectedPerawatId!.toString(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        if (success) {
          setState(() {
            _order = decoded['data'] as Map<String, dynamic>;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perawat berhasil ditugaskan.'),
            ),
          );

          // balik ke list & trigger refresh
          Navigator.pop(context, true);
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decoded['message']?.toString() ??
                  'Gagal menyimpan penugasan perawat.'),
            ),
          );
        }
      } else if (response.statusCode == 422) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                decoded['message']?.toString() ?? 'Validasi gagal (422).'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal menyimpan penugasan. Kode: ${response.statusCode} ${response.reasonPhrase}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigningPerawat = false;
        });
      }
    }
  }

  String _fmtTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _fmtJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    if (jam.length >= 5) return jam.substring(0, 5);
    return jam;
  }

  String _fmtUang(dynamic val) {
    if (val == null) return 'Rp 0';
    double d;
    if (val is num) {
      d = val.toDouble();
    } else {
      d = double.tryParse(val.toString()) ?? 0;
    }
    return 'Rp ${d.toStringAsFixed(0)}';
  }

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama']?.toString() ??
        obj['nama_lengkap']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  @override
  Widget build(BuildContext context) {
    final titleKode = _order?['kode_order']?.toString() ?? 'Detail Order';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleKode),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _initialLoad,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return const Center(
        child: Text('Data order kosong.'),
      );
    }

    final o = _order!;
    final pasien = o['pasien'] as Map<String, dynamic>?;
    final layanan = o['layanan'] as Map<String, dynamic>?;
    final perawat = o['perawat'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _initialLoad,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            'Info Order',
            children: [
              _row('Kode Order', o['kode_order']),
              _chipStatus(o['status_order']?.toString() ?? 'pending'),
              _row('Tanggal mulai', _fmtTanggal(o['tanggal_mulai']?.toString())),
              _row('Jam mulai', _fmtJam(o['jam_mulai']?.toString())),
              _row('Metode bayar', o['metode_pembayaran']),
              _row('Status bayar', o['status_pembayaran']),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Layanan',
            children: [
              _row('Nama layanan',
                  o['nama_layanan'] ?? layanan?['nama_layanan']),
              _row('Tipe layanan', o['tipe_layanan']),
              _row('Jumlah visit dipesan', o['jumlah_visit_dipesan']),
              _row('Durasi / visit (menit)', o['durasi_menit_per_visit']),
              _row('Qty', o['qty']),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Lokasi & Catatan',
            children: [
              _row('Alamat lengkap', o['alamat_lengkap']),
              _row('Kecamatan', o['kecamatan']),
              _row('Kota/Kabupaten', o['kota']),
              _row('Latitude', o['latitude']),
              _row('Longitude', o['longitude']),
              _row('Catatan pasien', o['catatan_pasien']),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Pasien',
            children: [
              _row('Nama pasien', _getNama(pasien)),
              _row('No RM', pasien?['no_rekam_medis']),
              _row('No HP', pasien?['no_hp']),
              _row('Email', pasien?['email']),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Perawat',
            children: [
              _row('Nama perawat sekarang', _getNama(perawat)),
              _row('ID perawat', perawat?['id']),
              const SizedBox(height: 8),
              _buildPerawatAssignSection(),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Pembayaran',
            children: [
              _row('Harga satuan', _fmtUang(o['harga_satuan'])),
              _row('Subtotal', _fmtUang(o['subtotal'])),
              _row('Diskon', _fmtUang(o['diskon'])),
              _row('Biaya tambahan', _fmtUang(o['biaya_tambahan'])),
              _row('Total bayar', _fmtUang(o['total_bayar'])),
              _row('Dibayar pada', o['dibayar_pada']),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPerawatAssignSection() {
    if (_isLoadingPerawat) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_perawats.isEmpty) {
      return const Text(
        'Belum ada perawat di bawah koordinator ini.',
        style: TextStyle(fontSize: 12, color: Colors.redAccent),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih / ubah perawat:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedPerawatId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: _perawats.map((p) {
            final id = p['id'] as int;
            final nama =
                p['nama_lengkap']?.toString() ?? p['nama']?.toString() ?? '-';
            final kode = p['kode_perawat']?.toString();
            final wilayah = p['wilayah']?.toString();

            String label = nama;
            if (kode != null && kode.isNotEmpty) {
              label = '$nama ($kode)';
            }
            if (wilayah != null && wilayah.isNotEmpty) {
              label = '$label - $wilayah';
            }

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedPerawatId = val;
            });
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isAssigningPerawat ? null : _assignPerawat,
            icon: _isAssigningPerawat
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.assignment_ind),
            label: Text(
              _isAssigningPerawat ? 'Menyimpan...' : 'Simpan Penugasan Perawat',
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, {required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    final text = (value == null || value.toString().isEmpty)
        ? '-'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(
            ':  ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipStatus(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'menunggu_penugasan':
        color = Colors.deepOrange;
        break;
      case 'mendapatkan_perawat':
        color = Colors.blue;
        break;
      case 'selesai':
        color = Colors.green;
        break;
      case 'dibatalkan':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
