// lib/chat.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // kalau nggak dipakai, boleh kamu hapus

import 'package:flutter/material.dart';
import 'package:home_care/users/buat_order_dari_chat_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat/chat_models.dart';

const String kBaseUrl = 'http://192.168.1.6:8000/api';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String roomTitle;
  final String role; // 'pasien' atau 'koordinator'

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.role,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  bool _isLoading = true;
  String? _error;

  int? _dealHarga; // hasil parsing angka dari [DEAL HARGA]
  int? _currentLayananIdFromChat; // layanan dari ETALASE terakhir

  List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _tawarHargaController = TextEditingController();
  final TextEditingController _tawarCatatanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentUserId = 0;
  bool _hasOrdered = false; // kalau true => tombol "Pesan Layanan Sekarang" disembunyikan

  // ====== ETALASE STATE ======
  List<Map<String, dynamic>> _etalaseLayanan = [];
  bool _isLoadingEtalase = false;
  String? _etalaseError;

  // 🔁 polling
  Timer? _pollTimer;
  bool _isFetching = false;

  // ============================
  // SCROLL HELPER
  // ============================
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ============================
  // APPEND MESSAGE TANPA RELOAD
  // ============================
  void _appendMessageFromResponse(http.Response res) {
    try {
      final body = json.decode(res.body);
      final data = body['data'];

      if (data == null) return;

      final newMsg = ChatMessage.fromJson(
        data as Map<String, dynamic>,
        currentUserId: _currentUserId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(newMsg);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Gagal parse message dari response: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserId();
    await _loadMessages(); // load pertama
    _startPolling(); // lalu polling
  }

  // ============================
  // HELPERS TAWAR & DEAL HARGA
  // ============================
  bool _isTawarHargaText(String text) {
    return text.trim().startsWith('[PENAWARAN HARGA]');
  }

  bool _isDealHargaText(String text) {
    return text.trim().startsWith('[DEAL HARGA]');
  }

  String? _extractNominalFromText(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('nominal:') || lower.startsWith('disepakati:')) {
        final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) return digits;
      }
    }
    return null;
  }

  Future<bool> _sendDealHarga(String nominal) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login berakhir, silakan login ulang.'),
        ),
      );
      return false;
    }

    final prefix = widget.role == 'koordinator'
        ? '/koordinator/chat-rooms'
        : '/pasien/chat-rooms';

    final url = '$kBaseUrl$prefix/${widget.roomId}/messages';
    print('POST DEAL HARGA $url');

    final buffer = StringBuffer()
      ..writeln('[DEAL HARGA]')
      ..writeln('Disepakati: Rp $nominal')
      ..writeln('Disepakati oleh: ${widget.role}');

    final res = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'message': buffer.toString()},
    );

    print('SEND DEAL STATUS: ${res.statusCode}');
    print('SEND DEAL BODY  : ${res.body}');

    if (res.statusCode == 201) {
      _appendMessageFromResponse(res);
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim DEAL harga (${res.statusCode})'),
        ),
      );
      return false;
    }
  }

  Future<void> _approveTawarFromMessage(ChatMessage msg) async {
    final nominal = _extractNominalFromText(msg.text);
    if (nominal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membaca nominal dari penawaran.'),
        ),
      );
      return;
    }

    await _sendDealHarga(nominal);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _tawarHargaController.dispose();
    _tawarCatatanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id') ?? 0;
    print('CURRENT USER ID: $_currentUserId');
  }

  // ============================
  // BOTTOM SHEET TAWAR HARGA
  // ============================
  void _openTawarHargaSheet() {
    if (widget.role != 'pasien') return;

    _tawarHargaController.clear();
    _tawarCatatanController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tawar Harga Layanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tawarHargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal tawaran (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tawarCatatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Misalnya: untuk 1x visit luka, bisa ya dok?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await _sendTawarHarga(
                        _tawarHargaController.text,
                        _tawarCatatanController.text,
                      );
                      if (success && mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Kirim Penawaran'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(fromPolling: true);
    });
  }

  // ==========================================
  //  FETCH LIST LAYANAN UNTUK ETALASE
  // ==========================================
  Future<void> _fetchEtalaseLayanan() async {
    setState(() {
      _isLoadingEtalase = true;
      _etalaseError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoadingEtalase = false;
          _etalaseError = 'Token tidak ditemukan, silakan login ulang.';
        });
        return;
      }

      final url = '$kBaseUrl/layanan';
      print('GET ETALASE: $url');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ETALASE STATUS: ${res.statusCode}');
      print('ETALASE BODY  : ${res.body}');

      if (res.statusCode != 200) {
        String? msg;
        try {
          final jsonBody = json.decode(res.body);
          msg = jsonBody['message']?.toString();
        } catch (_) {}
        setState(() {
          _isLoadingEtalase = false;
          _etalaseError =
              'Gagal memuat etalase (${res.statusCode})'
              '${msg != null ? '\n$msg' : ''}';
        });
        return;
      }

      final decoded = json.decode(res.body);

      List list;
      if (decoded is List) {
        list = decoded;
      } else {
        list = (decoded['data'] ?? []) as List;
      }

      final host = kBaseUrl.replaceFirst('/api', '');

      setState(() {
        _etalaseLayanan = list.map<Map<String, dynamic>>((e) {
          String? gambarUrl;
          if (e['gambar'] != null && (e['gambar'] as String).isNotEmpty) {
            final raw = e['gambar'] as String;
            gambarUrl = '$host/api/media/${raw.replaceFirst('storage/', '')}';
          }

          return {
            'id': e['id'],
            'nama_layanan': e['nama_layanan'] ?? 'Layanan',
            'deskripsi': e['deskripsi'],
            'durasi_menit': e['durasi_menit'],
            'kategori': e['kategori'],
            'syarat_perawat': e['syarat_perawat'],
            'lokasi_tersedia': e['lokasi_tersedia'],
            'gambar': gambarUrl,
          };
        }).toList();

        _isLoadingEtalase = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEtalase = false;
        _etalaseError = 'Error memuat etalase: $e';
      });
    }
  }

  // ==========================================
  //  FETCH PESAN CHAT
  // ==========================================
  Future<void> _loadMessages({bool fromPolling = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    final oldLen = _messages.length;

    if (!fromPolling) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Token tidak ditemukan, silakan login ulang.';
          });
        }
        _isFetching = false;
        return;
      }

      final prefix = widget.role == 'koordinator'
          ? '/koordinator/chat-rooms'
          : '/pasien/chat-rooms';

      final url = '$kBaseUrl$prefix/${widget.roomId}/messages';
      print('GET $url');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('RESPONSE STATUS: ${res.statusCode}');

      if (res.statusCode != 200) {
        if (!fromPolling && mounted) {
          String? msg;
          try {
            final jsonBody = json.decode(res.body);
            msg = jsonBody['message']?.toString();
          } catch (_) {}
          setState(() {
            _isLoading = false;
            _error =
                'Gagal memuat pesan (${res.statusCode})'
                '${msg != null ? '\n$msg' : ''}';
          });
        }
        _isFetching = false;
        return;
      }

      final body = json.decode(res.body);
      final List data = body['data'];

      print('==== RAW MESSAGE DATA ====');
      print(body['data']);
      print('==========================');

      final newMessages = data
          .map((e) => ChatMessage.fromJson(e, currentUserId: _currentUserId))
          .toList();

      if (mounted) {
        setState(() {
          _messages = newMessages;
          if (!fromPolling) {
            _isLoading = false;
            _error = null;
          }
        });

        if (newMessages.length > oldLen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      if (!fromPolling && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat pesan: $e';
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  // ==========================================
  //  SEND PESAN BIASA
  // ==========================================
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login berakhir, silakan login ulang.'),
        ),
      );
      return;
    }

    final prefix = widget.role == 'koordinator'
        ? '/koordinator/chat-rooms'
        : '/pasien/chat-rooms';

    final url = '$kBaseUrl$prefix/${widget.roomId}/messages';
    print('POST $url');

    final res = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'message': text},
    );

    print('SEND MESSAGE STATUS: ${res.statusCode}');
    print('SEND MESSAGE BODY  : ${res.body}');

    if (res.statusCode == 201) {
      _messageController.clear();
      _appendMessageFromResponse(res);
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak punya akses, silakan login ulang / cek role.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan (${res.statusCode})')),
      );
    }
  }

  // ==========================================
  //  BOTTOM SHEET ETALASE
  // ==========================================
  void _openEtalaseSheet() async {
    if (_etalaseLayanan.isEmpty && !_isLoadingEtalase) {
      await _fetchEtalaseLayanan();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        if (_isLoadingEtalase) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_etalaseError != null) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(_etalaseError!, textAlign: TextAlign.center),
            ),
          );
        }

        if (_etalaseLayanan.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Belum ada layanan pada etalase.')),
          );
        }

        return SafeArea(
          child: ListView.builder(
            itemCount: _etalaseLayanan.length,
            itemBuilder: (_, i) {
              final item = _etalaseLayanan[i];
              final nama = item['nama_layanan']?.toString() ?? 'Layanan';
              final gambar = item['gambar'] as String?;

              return ListTile(
                leading: (gambar != null && gambar.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          gambar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.medical_services_outlined),
                        ),
                      )
                    : const Icon(Icons.medical_services_outlined),
                title: Text(nama),
                subtitle: Text(
                  (item['durasi_menit'] != null)
                      ? "Durasi: ${item['durasi_menit']} menit"
                      : (item['kategori'] != null)
                          ? "Kategori: ${item['kategori']}"
                          : "",
                ),
                onTap: () {
                  _sendEtalase(item['id'] as int);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _sendTawarHarga(String harga, String? catatan) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login berakhir, silakan login ulang.'),
        ),
      );
      return false;
    }

    if (harga.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tawaran tidak boleh kosong.')),
      );
      return false;
    }

    final prefix = widget.role == 'koordinator'
        ? '/koordinator/chat-rooms'
        : '/pasien/chat-rooms';

    final url = '$kBaseUrl$prefix/${widget.roomId}/messages';
    print('POST TAWAR HARGA $url');

    final buffer = StringBuffer()
      ..writeln('[PENAWARAN HARGA]')
      ..writeln('Nominal: Rp $harga');

    if (catatan != null && catatan.trim().isNotEmpty) {
      buffer.writeln('Catatan: ${catatan.trim()}');
    }

    final res = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'message': buffer.toString()},
    );

    print('SEND TAWAR STATUS: ${res.statusCode}');
    print('SEND TAWAR BODY  : ${res.body}');

    if (res.statusCode == 201) {
      _tawarHargaController.clear();
      _tawarCatatanController.clear();
      _appendMessageFromResponse(res);
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim penawaran harga (${res.statusCode})'),
        ),
      );
      return false;
    }
  }

  Future<void> _sendEtalase(int layananId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login berakhir, silakan login ulang.'),
        ),
      );
      return;
    }

    final url = '$kBaseUrl/pasien/chat-rooms/${widget.roomId}/etalase';

    final res = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'layanan_id': layananId.toString()},
    );

    print('==== SEND ETALASE ====');
    print('POST $url');
    print('layanan_id: $layananId');
    print('Response: ${res.statusCode}');
    print('Body: ${res.body}');
    print('======================');

    if (res.statusCode == 201) {
      _appendMessageFromResponse(res);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim etalase (${res.statusCode})')),
      );
    }
  }

  // ==========================================
  //  AKSI KETIKA "PESAN LAYANAN SEKARANG"
  // ==========================================
  Future<void> _onPesanLayananSekarang() async {
    if (_dealHarga == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga deal tidak ditemukan di chat.')),
      );
      return;
    }

    if (_currentLayananIdFromChat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data layanan dari etalase tidak ditemukan.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuatOrderDariChatPage(
          layananId: _currentLayananIdFromChat!,
          roomId: widget.roomId,
          kesepakatanHarga: _dealHarga!,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _hasOrdered = true; // 🔥 hilangkan tombol setelah order sukses
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil dibuat dari chat ini.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    //  PAIRING: ETALASE TERAKHIR + DEAL TERAKHIR
    // ==========================================
    String? dealHargaDisplay;
    String? dealNominal;
    int? lastEtalaseIndex;
    int? lastDealIndex;

    // reset konteks tiap build
    _currentLayananIdFromChat = null;
    _dealHarga = null;

    for (int i = 0; i < _messages.length; i++) {
      final m = _messages[i];

      if (m.isEtalase && m.etalaseData != null) {
        lastEtalaseIndex = i;
      }

      if (_isDealHargaText(m.text)) {
        final nominal = _extractNominalFromText(m.text);
        if (nominal != null) {
          dealNominal = nominal;
          lastDealIndex = i;
        }
      }
    }

    bool hasValidDealForLatestEtalase = false;

    if (lastEtalaseIndex != null &&
        lastDealIndex != null &&
        lastDealIndex! > lastEtalaseIndex!) {
      hasValidDealForLatestEtalase = true;

      final etalaseMsg = _messages[lastEtalaseIndex!];
      final e = etalaseMsg.etalaseData!;
      final rawId = e['layanan_id'] ?? e['id'];

      int? layananId;
      if (rawId is int) {
        layananId = rawId;
      } else if (rawId is String) {
        layananId = int.tryParse(rawId);
      }

      _currentLayananIdFromChat = layananId;

      if (dealNominal != null) {
        _dealHarga = int.tryParse(dealNominal!);
        dealHargaDisplay = 'Rp $dealNominal';
      } else {
        dealHargaDisplay = 'Disepakati (lihat chat)';
      }
    }

    final bool hasDeal = hasValidDealForLatestEtalase;

    final bool canShowOrderButton =
        hasDeal && widget.role == 'pasien' && !_hasOrdered;

    return Scaffold(
      appBar: AppBar(title: Text(widget.roomTitle)),
      body: Column(
        children: [
          // 🔔 BANNER DEAL HARGA
          if (hasDeal && dealHargaDisplay != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.green[50],
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'HARGA FINAL SUDAH DISEPAKATI: $dealHargaDisplay',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 📜 LIST PESAN
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final timeText = msg.createdAt == null
                              ? ''
                              : DateFormat('HH:mm').format(msg.createdAt!);

                          // 🟩 kartu etalase
                          if (msg.isEtalase && msg.etalaseData != null) {
                            final e = msg.etalaseData!;
                            final nama =
                                (e['nama'] ?? e['nama_layanan'] ?? 'Layanan')
                                    as String;
                            final gambar = e['gambar'];

                            return Align(
                              alignment: msg.isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 260,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (gambar != null &&
                                        (gambar as String).isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          gambar as String,
                                          height: 130,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(height: 130),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  nama,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (e['durasi_menit'] != null)
                                            Text(
                                              "Durasi: ${e['durasi_menit']} menit",
                                            ),
                                          if (e['kategori'] != null)
                                            Text(
                                              "Kategori: ${e['kategori']}",
                                            ),
                                          if (e['syarat_perawat'] != null)
                                            Text(
                                              "Perawat: ${e['syarat_perawat']}",
                                            ),
                                          if (e['lokasi_tersedia'] != null)
                                            Text(
                                              "Lokasi: ${e['lokasi_tersedia']}",
                                            ),
                                          const SizedBox(height: 6),
                                          if (timeText.isNotEmpty)
                                            Text(
                                              timeText,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // 🟦 bubble chat biasa
                          final isTawar = _isTawarHargaText(msg.text);

                          return Align(
                            alignment: msg.isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: msg.isMine
                                    ? Colors.blue[200]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: msg.isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(msg.text),

                                  // Tombol setujui harga (koordinator) — hanya kalau belum deal
                                  if (!hasDeal &&
                                      widget.role == 'koordinator' &&
                                      isTawar &&
                                      !msg.isMine) ...[
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: () =>
                                          _approveTawarFromMessage(msg),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Setujui harga ini',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],

                                  if (timeText.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      timeText,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 🌟 TOMBOL "PESAN LAYANAN SEKARANG" (PAKAI canShowOrderButton)
          if (canShowOrderButton)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Pesan Layanan Sekarang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _onPesanLayananSekarang,
                ),
              ),
            ),

          // 🔻 BAR INPUT & ICON
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (widget.role == 'pasien') ...[
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: _openEtalaseSheet,
                    tooltip: 'Kirim etalase layanan',
                  ),
                  if (!hasDeal)
                    IconButton(
                      icon: const Icon(Icons.price_change_outlined),
                      onPressed: _openTawarHargaSheet,
                      tooltip: 'Tawar harga layanan',
                    ),
                ],
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: hasDeal
                          ? 'Harga sudah final, silakan lanjut komunikasi...'
                          : 'Tulis pesan...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
