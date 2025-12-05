import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const String kBaseUrl = 'http://192.168.1.6:8000/api';

class DetailOrderanMasukPerawatPage extends StatefulWidget {
  final int orderId;

  const DetailOrderanMasukPerawatPage({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<DetailOrderanMasukPerawatPage> createState() =>
      _DetailOrderanMasukPerawatPageState();
}

class _DetailOrderanMasukPerawatPageState
    extends State<DetailOrderanMasukPerawatPage> {
  bool _isLoading = true;
  String? _error;
  XFile? _fotoHadir;
  bool _isUploadingSampai = false;
  XFile? _fotoSelesai;
  bool _isUploadingSelesai = false;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _onMulaiVisit() async {
    if (_order == null) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Tindakan'),
        content: const Text(
          'Apakah Anda sudah bertemu pasien dan siap memulai tindakan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Mulai'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(
        '$kBaseUrl/perawat/order-layanan/${widget.orderId}/mulai-visit',
      );

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final success = decoded['success'] == true;

        if (success) {
          setState(() {
            _order = decoded['data'];
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['message'].toString())),
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['message'].toString())),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai visit. Kode: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _pickFotoHadir() async {
    try {
      ImageSource? source;

      if (kIsWeb) {
        // 🔥 Web: langsung buka file picker (galeri)
        source = ImageSource.gallery;
      } else {
        // 🔥 Mobile: pilih kamera / galeri
        source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Kamera'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galeri'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  ),
                ],
              ),
            );
          },
        );
      }

      if (source == null) return; // user batal

      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _fotoHadir = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto hadir berhasil dipilih.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  Future<void> _pickFotoSelesai() async {
    try {
      ImageSource? source;

      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Kamera'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galeri'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  ),
                ],
              ),
            );
          },
        );
      }

      if (source == null) return;

      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _fotoSelesai = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto selesai tindakan berhasil dipilih.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  Future<void> _onSudahSampaiDiTempat() async {
    if (_order == null) return;

    if (_fotoHadir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil / pilih foto hadir terlebih dahulu.'),
        ),
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Anda yakin sudah sampai di lokasi pasien dan ingin mengirim bukti foto hadir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Kirim'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploadingSampai = true;
    });

    try {
      final uri = Uri.parse(
        '$kBaseUrl/perawat/order-layanan/${widget.orderId}/sampai',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        // 🔥 Web: pakai bytes, bukan path
        final bytes = await _fotoHadir!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_hadir',
            bytes,
            filename: _fotoHadir!.name,
          ),
        );
      } else {
        // 🔥 Mobile: aman pakai path
        request.files.add(
          await http.MultipartFile.fromPath('foto_hadir', _fotoHadir!.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        setState(() {
          _isUploadingSampai = false;
        });

        if (success) {
          setState(() {
            _order = decoded['data'] as Map<String, dynamic>;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ??
                    'Berhasil ditandai sudah sampai di tempat.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ??
                    'Gagal mengirim status sudah sampai.',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isUploadingSampai = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengirim status sudah sampai. Kode: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingSampai = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _onSelesaiTindakan() async {
    if (_order == null) return;

    if (_fotoSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan ambil / pilih foto setelah tindakan terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah tindakan sudah selesai dan Anda ingin mengirim foto dokumentasi akhir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploadingSelesai = true;
    });

    try {
      final uri = Uri.parse(
        '$kBaseUrl/perawat/order-layanan/${widget.orderId}/selesai',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        final bytes = await _fotoSelesai!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_selesai',
            bytes,
            filename: _fotoSelesai!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('foto_selesai', _fotoSelesai!.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        setState(() {
          _isUploadingSelesai = false;
        });

        if (success) {
          setState(() {
            _order = decoded['data'] as Map<String, dynamic>;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ??
                    'Tindakan selesai dan foto dokumentasi tersimpan.',
              ),
            ),
          );

          // opsional: balik ke list sambil kirim sinyal refresh
          // Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ??
                    'Gagal menyimpan status selesai.',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isUploadingSelesai = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan status selesai. Kode: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingSelesai = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Token tidak ditemukan. Silakan login sebagai perawat.';
      });
      return;
    }

    try {
      final uri = Uri.parse(
        '$kBaseUrl/perawat/order-layanan/${widget.orderId}',
      );

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
            _error =
                decoded['message']?.toString() ?? 'Gagal memuat detail order.';
          });
          return;
        }

        setState(() {
          _order = decoded['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _error = 'Order tidak ditemukan atau bukan milik Anda.';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login perawat berakhir. Silakan login ulang.';
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

  String? _mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;

    // Kalau sudah full URL, langsung pakai
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Buang slash di awal, kalau ada
    var cleanPath = path;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // /api/media/{path}
    return '$kBaseUrl/media/$cleanPath';
  }

  Widget _fotoItem(String label, String? path) {
    final url = _mediaUrl(path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        if (url == null)
          const Text('Belum ada foto', style: TextStyle(fontSize: 13))
        else
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain, // tidak crop, tidak melebar
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _onTerimaOrder() async {
    if (_order == null) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Anda yakin ingin menerima order ini dan menuju lokasi pasien?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 endpoint terima order perawat
      final uri = Uri.parse(
        '$kBaseUrl/perawat/order-layanan/${widget.orderId}/terima',
      );

      final response = await http.post(
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

        if (success) {
          setState(() {
            _order = decoded['data'] as Map<String, dynamic>;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ??
                    'Order diterima. Anda akan menuju lokasi pasien.',
              ),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ?? 'Gagal menerima order.',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerima order. Kode: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _onTolakOrder() async {
    if (_order == null) return;

    final alasanController = TextEditingController();

    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tolak Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Silakan isi alasan kenapa Anda menolak order ini.'),
              const SizedBox(height: 8),
              TextField(
                controller: alasanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Jadwal saya bentrok, lokasi terlalu jauh, dsb.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = alasanController.text.trim();
                if (text.isEmpty) {
                  // simple validation di dialog
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Alasan tidak boleh kosong')),
                  );
                  return;
                }
                Navigator.of(ctx).pop(text);
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );

    if (hasil == null || hasil.trim().isEmpty) {
      return; // user batal
    }

    final alasan = hasil.trim();

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 endpoint tolak order perawat
      final uri = Uri.parse(
        '$kBaseUrl/perawat/order-layanan/${widget.orderId}/tolak',
      );

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'alasan': alasan}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ?? 'Order berhasil ditolak.',
              ),
            ),
          );

          // Biasanya setelah menolak, order ini tidak muncul lagi di list perawat.
          // Jadi enak kalau langsung kembali ke halaman sebelumnya:
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decoded['message']?.toString() ?? 'Gagal menolak order.',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak order. Kode: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
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
    return obj['nama_lengkap']?.toString() ??
        obj['nama']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  @override
  Widget build(BuildContext context) {
    final titleKode = _order?['kode_order']?.toString() ?? 'Detail Order';

    return Scaffold(
      appBar: AppBar(title: Text(titleKode)),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(), // 🔥 tambahkan ini
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _order == null) {
      return const SizedBox.shrink();
    }

    final status = _order!['status_order']?.toString() ?? 'pending';

    // 1) Saat baru ditunjuk → bisa Terima / Tolak
    if (status == 'mendapatkan_perawat') {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onTolakOrder,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tolak',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onTerimaOrder,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Terima dan Saya Akan Kesana',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2) Saat sudah dalam perjalanan → harus upload foto + tandai "sampai"
    if (status == 'sedang_dalam_perjalanan') {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingSampai ? null : _pickFotoHadir,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _fotoHadir == null
                            ? 'Ambil Foto Hadir'
                            : 'Ulangi Foto Hadir',
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isUploadingSampai || _fotoHadir == null)
                      ? null
                      : _onSudahSampaiDiTempat,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isUploadingSampai
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Sudah Sampai di Tempat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 3) Saat sudah sampai → tombol "Saya sudah bertemu pasien"
    if (status == 'sampai_ditempat') {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onMulaiVisit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Saya sudah bertemu pasien',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }
    // 4) Saat tindakan sedang berjalan → upload foto selesai + "Selesai tindakan"
    if (status == 'sedang_berjalan') {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingSelesai ? null : _pickFotoSelesai,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _fotoSelesai == null
                            ? 'Ambil foto setelah selesai tindakan'
                            : 'Ulangi foto selesai',
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isUploadingSelesai || _fotoSelesai == null)
                      ? null
                      : _onSelesaiTindakan,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isUploadingSelesai
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Selesai tindakan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
                onPressed: _fetchDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Data order kosong.'));
    }

    final o = _order!;
    final pasien = o['pasien'] as Map<String, dynamic>?;
    final layanan = o['layanan'] as Map<String, dynamic>?;
    final koordinator = o['koordinator'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            'Info Order',
            children: [
              _row('Kode Order', o['kode_order']),
              _chipStatus(o['status_order']?.toString() ?? 'pending'),
              _row(
                'Tanggal mulai',
                _fmtTanggal(o['tanggal_mulai']?.toString()),
              ),
              _row('Jam mulai', _fmtJam(o['jam_mulai']?.toString())),

              // 🔥 TAMBAH INI
              _row(
                'Jam keberangkatan',
                _fmtJam(o['jam_keberangkatan']?.toString()),
              ),

              _row('Metode bayar', o['metode_pembayaran']),
              _row('Status bayar', o['status_pembayaran']),
            ],
          ),

          const SizedBox(height: 12),
          _section(
            'Layanan',
            children: [
              _row(
                'Nama layanan',
                o['nama_layanan'] ?? layanan?['nama_layanan'],
              ),
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
            'Koordinator',
            children: [
              _row('Nama koordinator', _getNama(koordinator)),
              _row('ID koordinator', koordinator?['id']),
              _row('Wilayah', koordinator?['wilayah']),
              _row('No HP', koordinator?['no_hp']),
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
          _section(
            'Dokumentasi Foto',
            children: [
              _fotoItem('Kondisi pasien (awal)', o['kondisi_pasien']),
              _fotoItem('Foto hadir di lokasi', o['foto_hadir']),
              _fotoItem('Foto setelah selesai tindakan ', o['foto_selesai']),
            ],
          ),
          const SizedBox(height: 16),
          // Nanti kalau mau tombol "Mulai Visit" / "Selesai", bisa taruh di sini
        ],
      ),
    );
  }

  Widget _section(String title, {required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Text(':  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _chipStatus(String status) {
    Color color;
    String label = status;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'menunggu_penugasan':
        color = Colors.deepOrange;
        label = 'Menunggu penugasan';
        break;
      case 'mendapatkan_perawat':
        color = Colors.blue;
        label = 'Menunggu respon perawat';
        break;
      case 'sedang_dalam_perjalanan':
        color = Colors.teal;
        label = 'Dalam perjalanan';
        break;
      case 'sampai_ditempat':
        color = Colors.indigo;
        label = 'Sudah sampai';
        break;
      case 'sedang_berjalan':
        color = Colors.purple;
        label = 'Sedang berjalan';
        break;
      case 'selesai':
        color = Colors.green;
        label = 'Selesai';
        break;
      case 'dibatalkan':
        color = Colors.red;
        label = 'Dibatalkan';
        break;
      default:
        color = Colors.grey;
        label = status;
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
            label,
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
