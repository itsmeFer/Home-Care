import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat/chat_models.dart';
import 'users/buat_order_dari_chat_page.dart';

const String kBaseUrl = 'http://192.168.1.5:8000/api';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String roomTitle;
  final String role; // pasien / koordinator / perawat
  final bool simpleChat;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.role,
    this.simpleChat = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _tawarHargaController = TextEditingController();
  final TextEditingController _tawarCatatanController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<ChatMessage> _messages = [];

  Timer? _pollTimer;

  bool _isLoading = true;
  bool _isFetching = false;
  bool _isSending = false;
  bool _isUploadingImage = false;
  bool _isLoadingEtalase = false;
  bool _canSend = true;
  bool _hasOrdered = false;
  bool _isDisposed = false;

  String? _error;
  String? _chatStatus;
  String? _etalaseError;

  int _currentUserId = 0;
  int? _dealHarga;
  int? _currentLayananIdFromChat;

  List<Map<String, dynamic>> _etalaseLayanan = [];

  DateTime? _lastSendAt;
  String _lastSentText = '';

  String get _apiPrefixForRole {
    switch (widget.role) {
      case 'koordinator':
        return '/koordinator/chat-rooms';
      case 'perawat':
        return '/perawat/chat-rooms';
      default:
        return '/pasien/chat-rooms';
    }
  }

  bool get _isCoordinatorBlocked => widget.role == 'koordinator' && !_canSend;

  bool get _isPasienPerawat =>
      widget.role == 'pasien' &&
      widget.roomTitle.toLowerCase().contains('perawat');

  bool get _negoEnabled =>
      !widget.simpleChat && !_isPasienPerawat && widget.role != 'perawat';

  String get _statusLabel {
    switch (_chatStatus) {
      case 'tawar':
        return 'Negosiasi Harga';
      case 'deal':
        return 'Deal Harga';
      case 'orderan_berjalan':
        return 'Order Berjalan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Chat Aktif';
    }
  }

  Color get _statusColor {
    switch (_chatStatus) {
      case 'tawar':
        return const Color(0xFFFF9F0A);
      case 'deal':
        return const Color(0xFF34C759);
      case 'orderan_berjalan':
        return const Color(0xFF007AFF);
      case 'selesai':
        return const Color(0xFF8E8E93);
      case 'dibatalkan':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF636366);
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollTimer?.cancel();
    _messageController.dispose();
    _tawarHargaController.dispose();
    _tawarCatatanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadUserId();
    await _loadMessages();
    _startPolling();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id') ?? 0;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isDisposed) {
        _loadMessages(fromPolling: true);
      }
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.position.maxScrollExtent + 120;
    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(offset);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  bool _isDuplicateSend(String text) {
    final now = DateTime.now();
    if (_lastSendAt == null) return false;

    final diff = now.difference(_lastSendAt!).inMilliseconds;
    return _lastSentText == text && diff < 2000;
  }

  bool _isSameMessageList(List<ChatMessage> oldList, List<ChatMessage> newList) {
    if (oldList.length != newList.length) return false;

    for (int i = 0; i < oldList.length; i++) {
      final oldMsg = oldList[i];
      final newMsg = newList[i];

      if (oldMsg.id != newMsg.id) return false;
      if (oldMsg.text != newMsg.text) return false;
      if (oldMsg.type != newMsg.type) return false;
      if (oldMsg.fileUrl != newMsg.fileUrl) return false;
      if (oldMsg.createdAt != newMsg.createdAt) return false;
    }

    return true;
  }

  Future<void> _loadMessages({bool fromPolling = false}) async {
    if (_isFetching || _isDisposed) return;

    _isFetching = true;
    final oldLen = _messages.length;

    if (!fromPolling && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final token = await _getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan, silakan login ulang.';
        });
        return;
      }

      final url = '$kBaseUrl$_apiPrefixForRole/${widget.roomId}/messages';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        if (!fromPolling && mounted) {
          String msg = 'Gagal memuat pesan (${res.statusCode})';
          try {
            final body = json.decode(res.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'].toString();
            }
          } catch (_) {}
          setState(() {
            _isLoading = false;
            _error = msg;
          });
        }
        return;
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = (body['data'] as List?) ?? [];

      final newMessages = data
          .map(
            (e) => ChatMessage.fromJson(
              e as Map<String, dynamic>,
              currentUserId: _currentUserId,
            ),
          )
          .toList();

      final canSendFromApi = body['can_send'];
      final hasOrderFromApi = body['has_order'];
      final statusFromApi = body['status'];

      final hasChanged = !_isSameMessageList(_messages, newMessages);

      if (!mounted || _isDisposed) return;

      setState(() {
        if (hasChanged) {
          _messages
            ..clear()
            ..addAll(newMessages);
        }

        if (canSendFromApi is bool) {
          _canSend = canSendFromApi;
        }
        if (hasOrderFromApi is bool) {
          _hasOrdered = hasOrderFromApi;
        }
        if (statusFromApi is String) {
          _chatStatus = statusFromApi;
        }

        _isLoading = false;
        _error = null;
      });

      if (newMessages.length > oldLen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            _scrollToBottom(animated: true);
          }
        });
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

  void _appendMessageFromResponse(http.Response res) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data == null) return;

      final newMsg = ChatMessage.fromJson(
        data as Map<String, dynamic>,
        currentUserId: _currentUserId,
      );

      if (!mounted || _isDisposed) return;

      final alreadyExists = _messages.any((m) => m.id == newMsg.id);

      setState(() {
        if (!alreadyExists) {
          _messages.add(newMsg);
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          _scrollToBottom();
        }
      });
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;
    if (_isSending || _isUploadingImage) return;

    if (_isDuplicateSend(text)) {
      _showSnack('Pesan yang sama baru saja dikirim.');
      return;
    }

    if (_isCoordinatorBlocked) {
      _showSnack('Chat ini sudah ditutup oleh pasien.');
      return;
    }

    FocusScope.of(context).unfocus();

    final token = await _getToken();
    if (token == null) {
      _showSnack('Sesi login berakhir, silakan login ulang.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final url = '$kBaseUrl$_apiPrefixForRole/${widget.roomId}/messages';
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'message': text},
      );

      if (res.statusCode == 201) {
        _lastSendAt = DateTime.now();
        _lastSentText = text;

        _messageController.clear();
        _appendMessageFromResponse(res);
      } else {
        String msg = 'Gagal mengirim pesan (${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}

        if (res.statusCode == 403 && widget.role == 'koordinator') {
          setState(() => _canSend = false);
        }

        _showSnack(msg);
      }
    } catch (e) {
      _showSnack('Gagal mengirim pesan: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingImage || _isSending || _isCoordinatorBlocked) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassBottomSheet(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _SheetActionTile(
                icon: CupertinoIcons.photo_on_rectangle,
                title: 'Pilih dari galeri',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              _SheetActionTile(
                icon: CupertinoIcons.camera,
                title: 'Ambil dari kamera',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );

    if (picked == null) return;

    final token = await _getToken();
    if (token == null) {
      _showSnack('Sesi login berakhir, silakan login ulang.');
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final uri = Uri.parse('$kBaseUrl$_apiPrefixForRole/${widget.roomId}/messages');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['message'] = _messageController.text.trim()
        ..files.add(await http.MultipartFile.fromPath('image', picked.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 201) {
        _messageController.clear();
        _appendMessageFromResponse(res);
      } else {
        String msg = 'Gagal mengirim gambar (${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}
        _showSnack(msg);
      }
    } catch (e) {
      _showSnack('Upload gambar gagal: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _fetchEtalaseLayanan() async {
    setState(() {
      _isLoadingEtalase = true;
      _etalaseError = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _isLoadingEtalase = false;
          _etalaseError = 'Token tidak ditemukan, silakan login ulang.';
        });
        return;
      }

      final res = await http.get(
        Uri.parse('$kBaseUrl/layanan'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        setState(() {
          _isLoadingEtalase = false;
          _etalaseError = 'Gagal memuat etalase (${res.statusCode})';
        });
        return;
      }

      final decoded = json.decode(res.body);
      final list =
          decoded is List ? decoded : ((decoded['data'] ?? []) as List);
      final host = kBaseUrl.replaceFirst('/api', '');

      setState(() {
        _etalaseLayanan = list.map<Map<String, dynamic>>((e) {
          final item = e as Map<String, dynamic>;
          String? gambarUrl;
          final raw = item['gambar']?.toString();
          if (raw != null && raw.isNotEmpty) {
            gambarUrl = '$host/api/media/${raw.replaceFirst('storage/', '')}';
          }
          return {
            'id': item['id'],
            'nama_layanan': item['nama_layanan'] ?? 'Layanan',
            'deskripsi': item['deskripsi'],
            'durasi_menit': item['durasi_menit'],
            'kategori': item['kategori'],
            'syarat_perawat': item['syarat_perawat'],
            'lokasi_tersedia': item['lokasi_tersedia'],
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

  void _openEtalaseSheet() async {
    if (_etalaseLayanan.isEmpty && !_isLoadingEtalase) {
      await _fetchEtalaseLayanan();
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (_isLoadingEtalase) {
          return const _GlassBottomSheet(
            child: SizedBox(
              height: 180,
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
          );
        }

        if (_etalaseError != null) {
          return _GlassBottomSheet(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Text(_etalaseError!, textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return _GlassBottomSheet(
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _etalaseLayanan.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = _etalaseLayanan[i];
                  final image = item['gambar']?.toString();
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.pop(context);
                      _sendEtalase(item['id'] as int);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 58,
                              height: 58,
                              child: image != null && image.isNotEmpty
                                  ? Image.network(
                                      image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _imageFallback(),
                                    )
                                  : _imageFallback(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama_layanan']?.toString() ?? 'Layanan',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['durasi_menit'] != null
                                      ? 'Durasi ${item['durasi_menit']} menit'
                                      : (item['kategori']?.toString() ?? '-'),
                                  style: const TextStyle(
                                    color: Color(0xFF636366),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(CupertinoIcons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: const Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93)),
    );
  }

  Future<void> _sendEtalase(int layananId) async {
    if (_isSending || _isUploadingImage) return;

    final token = await _getToken();
    if (token == null) {
      _showSnack('Sesi login berakhir, silakan login ulang.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/pasien/chat-rooms/${widget.roomId}/etalase'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'layanan_id': layananId.toString()},
      );

      if (res.statusCode == 201) {
        _appendMessageFromResponse(res);
      } else {
        _showSnack('Gagal mengirim etalase (${res.statusCode})');
      }
    } catch (e) {
      _showSnack('Gagal mengirim etalase: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _isTawarHargaText(String text) =>
      text.trim().startsWith('[PENAWARAN HARGA]');

  bool _isDealHargaText(String text) =>
      text.trim().startsWith('[DEAL HARGA]');

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

  Future<bool> _sendTawarHarga(String harga, String? catatan) async {
    if (_isSending || _isUploadingImage) return false;

    final token = await _getToken();
    if (token == null) {
      _showSnack('Sesi login berakhir, silakan login ulang.');
      return false;
    }

    if (harga.trim().isEmpty) {
      _showSnack('Nominal tawaran tidak boleh kosong.');
      return false;
    }

    final buffer = StringBuffer()
      ..writeln('[PENAWARAN HARGA]')
      ..writeln('Nominal: Rp $harga');

    if (catatan != null && catatan.trim().isNotEmpty) {
      buffer.writeln('Catatan: ${catatan.trim()}');
    }

    final messageText = buffer.toString();

    if (_isDuplicateSend(messageText)) {
      _showSnack('Penawaran yang sama baru saja dikirim.');
      return false;
    }

    setState(() => _isSending = true);

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl$_apiPrefixForRole/${widget.roomId}/messages'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'message': messageText},
      );

      if (res.statusCode == 201) {
        _lastSendAt = DateTime.now();
        _lastSentText = messageText;

        _tawarHargaController.clear();
        _tawarCatatanController.clear();
        _appendMessageFromResponse(res);
        return true;
      }

      _showSnack('Gagal mengirim penawaran harga (${res.statusCode})');
      return false;
    } catch (e) {
      _showSnack('Gagal mengirim penawaran: $e');
      return false;
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<bool> _sendDealHarga(String nominal) async {
    if (_isSending || _isUploadingImage) return false;

    final token = await _getToken();
    if (token == null) {
      _showSnack('Sesi login berakhir, silakan login ulang.');
      return false;
    }

    final buffer = StringBuffer()
      ..writeln('[DEAL HARGA]')
      ..writeln('Disepakati: Rp $nominal')
      ..writeln('Disepakati oleh: ${widget.role}');

    final messageText = buffer.toString();

    if (_isDuplicateSend(messageText)) {
      _showSnack('Pesan deal yang sama baru saja dikirim.');
      return false;
    }

    setState(() => _isSending = true);

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl$_apiPrefixForRole/${widget.roomId}/messages'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'message': messageText},
      );

      if (res.statusCode == 201) {
        _lastSendAt = DateTime.now();
        _lastSentText = messageText;

        _appendMessageFromResponse(res);
        return true;
      }

      _showSnack('Gagal mengirim DEAL harga (${res.statusCode})');
      return false;
    } catch (e) {
      _showSnack('Gagal mengirim deal harga: $e');
      return false;
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _approveTawarFromMessage(ChatMessage msg) async {
    if (widget.role != 'koordinator') return;
    if (!_canSend) {
      _showSnack('Chat ini sudah ditutup oleh pasien. Tidak bisa menyetujui harga.');
      return;
    }

    final nominalStr = _extractNominalFromText(msg.text);
    if (nominalStr == null || nominalStr.isEmpty) {
      _showSnack('Nominal penawaran tidak ditemukan di pesan.');
      return;
    }

    final nominalInt = int.tryParse(nominalStr);
    if (nominalInt == null || nominalInt <= 0) {
      _showSnack('Nominal penawaran tidak valid.');
      return;
    }

    final formatter = NumberFormat.decimalPattern('id_ID');
    final formatted = formatter.format(nominalInt);

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Setujui Harga'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text('Setujui penawaran sebesar Rp $formatted?'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sendDealHarga(nominalInt.toString());
    }
  }

  void _openTawarHargaSheet() {
    _tawarHargaController.clear();
    _tawarCatatanController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassBottomSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: SizedBox(
                  width: 42,
                  child: Divider(
                    thickness: 4,
                    color: Color(0xFFD1D1D6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tawar Harga',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tulis nominal dan catatan singkat untuk koordinator.',
                style: TextStyle(color: Color(0xFF636366)),
              ),
              const SizedBox(height: 16),
              _frostField(
                controller: _tawarHargaController,
                keyboardType: TextInputType.number,
                hint: 'Nominal tawaran',
                prefix: 'Rp ',
              ),
              const SizedBox(height: 10),
              _frostField(
                controller: _tawarCatatanController,
                hint: 'Catatan opsional',
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () async {
                    final ok = await _sendTawarHarga(
                      _tawarHargaController.text,
                      _tawarCatatanController.text,
                    );
                    if (ok && mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Kirim Penawaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frostField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _onPesanLayananSekarang() async {
    if (_dealHarga == null) {
      _showSnack('Harga deal tidak ditemukan di chat.');
      return;
    }

    if (_currentLayananIdFromChat == null) {
      _showSnack('Data layanan dari etalase tidak ditemukan.');
      return;
    }

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
      setState(() => _hasOrdered = true);
      _showSnack('Order berhasil dibuat dari chat ini.');
    }
  }

  void _showSnack(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? dealHargaDisplay;
    String? dealNominal;
    int? lastEtalaseIndex;
    int? lastDealIndex;

    _currentLayananIdFromChat = null;
    _dealHarga = null;

    bool hasValidDealForLatestEtalase = false;

    if (_negoEnabled) {
      for (int i = 0; i < _messages.length; i++) {
        final m = _messages[i];
        if (m.isEtalase && m.etalaseData != null) lastEtalaseIndex = i;
        if (_isDealHargaText(m.text)) {
          final nominal = _extractNominalFromText(m.text);
          if (nominal != null) {
            dealNominal = nominal;
            lastDealIndex = i;
          }
        }
      }

      if (lastEtalaseIndex != null &&
          lastDealIndex != null &&
          lastDealIndex > lastEtalaseIndex) {
        hasValidDealForLatestEtalase = true;
        final etalaseMsg = _messages[lastEtalaseIndex];
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
          _dealHarga = int.tryParse(dealNominal);
          final formatted = NumberFormat.decimalPattern('id_ID').format(
            _dealHarga ?? 0,
          );
          dealHargaDisplay = 'Rp $formatted';
        }
      }
    }

    final hasDeal = hasValidDealForLatestEtalase;
    final canShowOrderButton =
        hasDeal && widget.role == 'pasien' && !_hasOrdered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F7),
        foregroundColor: Colors.black,
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _statusLabel,
              style: TextStyle(
                fontSize: 12,
                color: _statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  _StatusPill(label: _statusLabel, color: _statusColor),
                  if (_negoEnabled && hasDeal && dealHargaDisplay != null) ...[
                    const SizedBox(height: 10),
                    _DealBanner(label: dealHargaDisplay),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 14))
                  : _error != null
                      ? Center(child: Text(_error!))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final timeText = msg.createdAt == null
                                ? ''
                                : DateFormat('HH:mm').format(msg.createdAt!);

                            if (_negoEnabled &&
                                msg.isEtalase &&
                                msg.etalaseData != null) {
                              return _EtalaseBubble(
                                msg: msg,
                                timeText: timeText,
                              );
                            }

                            final isTawar = _isTawarHargaText(msg.text);
                            final imageUrl = _safeFileUrl(msg);

                            return _ChatBubble(
                              message: msg,
                              timeText: timeText,
                              imageUrl: imageUrl,
                              onImageTap: imageUrl == null
                                  ? null
                                  : () => _openImagePreview(imageUrl),
                              extra: _negoEnabled &&
                                      !hasDeal &&
                                      widget.role == 'koordinator' &&
                                      isTawar &&
                                      !msg.isMine
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        color: const Color(0xFF007AFF),
                                        borderRadius: BorderRadius.circular(12),
                                        minSize: 0,
                                        onPressed: () =>
                                            _approveTawarFromMessage(msg),
                                        child: const Text(
                                          'Setujui harga ini',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
            ),
            if (_negoEnabled && canShowOrderButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(18),
                    onPressed: _onPesanLayananSekarang,
                    child: const Text('Pesan Layanan Sekarang'),
                  ),
                ),
              ),
            _InputComposer(
              controller: _messageController,
              isBlocked: _isCoordinatorBlocked,
              isSending: _isSending || _isUploadingImage,
              showEtalase: widget.role == 'pasien' && _negoEnabled,
              showTawar: widget.role == 'pasien' && _negoEnabled && !hasDeal,
              onEtalaseTap: _openEtalaseSheet,
              onTawarTap: _openTawarHargaSheet,
              onImageTap: _pickAndSendImage,
              onSendTap: _sendMessage,
              hintText: _isCoordinatorBlocked
                  ? 'Chat ini sudah ditutup oleh pasien.'
                  : (hasDeal
                        ? 'Harga sudah final, lanjutkan komunikasi…'
                        : 'Tulis pesan…'),
            ),
          ],
        ),
      ),
    );
  }

  String? _safeFileUrl(ChatMessage msg) {
    try {
      if (msg.type == 'image') {
        final url = msg.fileUrl;
        if (url != null && url.toString().trim().isNotEmpty) {
          return url.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  void _openImagePreview(String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'image-preview',
      barrierColor: Colors.black.withOpacity(0.9),
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 52,
                  right: 20,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealBanner extends StatelessWidget {
  final String label;

  const _DealBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: Color(0xFF34C759),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Harga final disepakati: $label',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C7C3A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String timeText;
  final String? imageUrl;
  final VoidCallback? onImageTap;
  final Widget? extra;

  const _ChatBubble({
    required this.message,
    required this.timeText,
    this.imageUrl,
    this.onImageTap,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF007AFF)
                  : Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                imageUrl != null ? 8 : 14,
                imageUrl != null ? 8 : 12,
                imageUrl != null ? 8 : 14,
                10,
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null) ...[
                    GestureDetector(
                      onTap: onImageTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          imageUrl!,
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 220,
                            height: 220,
                            color: Colors.black12,
                            child: const Icon(CupertinoIcons.photo, size: 40),
                          ),
                        ),
                      ),
                    ),
                    if (message.text.trim().isNotEmpty)
                      const SizedBox(height: 10),
                  ],
                  if (message.text.trim().isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        height: 1.35,
                        color: isMine
                            ? Colors.white
                            : const Color(0xFF111111),
                        fontSize: 15,
                      ),
                    ),
                  if (extra != null) extra!,
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine
                          ? Colors.white70
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EtalaseBubble extends StatelessWidget {
  final ChatMessage msg;
  final String timeText;

  const _EtalaseBubble({required this.msg, required this.timeText});

  @override
  Widget build(BuildContext context) {
    final e = msg.etalaseData!;
    final nama = (e['nama'] ?? e['nama_layanan'] ?? 'Layanan').toString();
    final gambar = e['gambar']?.toString();

    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gambar != null && gambar.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Image.network(
                  gambar,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: const Color(0xFFF2F2F7),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MetaText(
                    label: 'Durasi',
                    value: e['durasi_menit'] != null
                        ? '${e['durasi_menit']} menit'
                        : null,
                  ),
                  _MetaText(label: 'Kategori', value: e['kategori']?.toString()),
                  _MetaText(
                    label: 'Perawat',
                    value: e['syarat_perawat']?.toString(),
                  ),
                  _MetaText(
                    label: 'Lokasi',
                    value: e['lokasi_tersedia']?.toString(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
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
}

class _MetaText extends StatelessWidget {
  final String label;
  final String? value;

  const _MetaText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3C)),
      ),
    );
  }
}

class _InputComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isBlocked;
  final bool isSending;
  final bool showEtalase;
  final bool showTawar;
  final String hintText;
  final VoidCallback onEtalaseTap;
  final VoidCallback onTawarTap;
  final VoidCallback onImageTap;
  final VoidCallback onSendTap;

  const _InputComposer({
    required this.controller,
    required this.isBlocked,
    required this.isSending,
    required this.showEtalase,
    required this.showTawar,
    required this.hintText,
    required this.onEtalaseTap,
    required this.onTawarTap,
    required this.onImageTap,
    required this.onSendTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ComposerAction(
              icon: CupertinoIcons.photo,
              onTap: isBlocked || isSending ? null : onImageTap,
            ),
            if (showEtalase)
              _ComposerAction(
                icon: CupertinoIcons.bag,
                onTap: isBlocked || isSending ? null : onEtalaseTap,
              ),
            if (showTawar)
              _ComposerAction(
                icon: CupertinoIcons.tag,
                onTap: isBlocked || isSending ? null : onTawarTap,
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  readOnly: isBlocked || isSending,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) {
                    if (!isBlocked && !isSending) {
                      onSendTap();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              child: CupertinoButton(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(999),
                onPressed: isBlocked || isSending ? null : onSendTap,
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CupertinoActivityIndicator(
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.arrow_up,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ComposerAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      minSize: 0,
      onPressed: onTap,
      child: Icon(
        icon,
        size: 22,
        color: onTap == null
            ? const Color(0xFFB0B0B5)
            : const Color(0xFF007AFF),
      ),
    );
  }
}

class _GlassBottomSheet extends StatelessWidget {
  final Widget child;

  const _GlassBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.65)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF007AFF)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}