import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';
import 'package:home_care/features/chat/data/services/chat_service.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_input_composer.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_messages_list.dart';
import 'package:home_care/features/chat/presentation/widgets/deal_banner.dart';
import 'package:home_care/features/chat/presentation/widgets/etalase_bottom_sheet.dart';
import 'package:home_care/features/chat/presentation/widgets/tawar_harga_bottom_sheet.dart';
import 'package:home_care/users/buat_order_dari_chat_page.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String roomTitle;
  final String role;
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

class _ChatRoomPageState extends State<ChatRoomPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> _messages = [];
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
  String get _chatStatus => _dealHarga != null ? 'deal' : 'active';
  String? _etalaseError;

  int _currentUserId = 0;
  int? _dealHarga;
  int? _currentLayananIdFromChat;

  List<EtalaseData> _etalaseLayanan = [];
  DateTime? _lastSendAt;
  String? _lastSentText;

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
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pollTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isDisposed) {
        _startPolling();
        _loadMessages(fromPolling: true);
      }
    }
  }

  Future<void> _init() async {
    final prefs = await StorageService.instance;
    _currentUserId = prefs.getInt(StorageService.keyUserId) ?? 0;
    await _loadMessages();
    _startPolling();
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

  bool _isDuplicateSend(String text) {
    final now = DateTime.now();
    if (_lastSentText == text && _lastSendAt != null) {
      final diff = now.difference(_lastSendAt!).inSeconds;
      if (diff < 3) return true;
    }
    return false;
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
      final newMessages = await ChatService.fetchRoomMessages(
        roomId: widget.roomId,
        role: widget.role,
        currentUserId: _currentUserId,
      );

      if (_isDisposed || !mounted) return;

      setState(() {
        _messages = newMessages;
        _isLoading = false;
        _error = null;
      });

      if (!fromPolling || newMessages.length > oldLen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed && mounted) {
            _scrollToBottom(animated: fromPolling);
          }
        });
      }
    } catch (e) {
      if (!fromPolling && mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _isUploadingImage || _isCoordinatorBlocked) {
      return;
    }

    if (_isDuplicateSend(text)) {
      _showSnack('Pesan yang sama baru saja dikirim.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final sent = await ChatService.sendMessage(
        roomId: widget.roomId,
        role: widget.role,
        message: text,
        currentUserId: _currentUserId,
      );

      if (sent != null) {
        _lastSendAt = DateTime.now();
        _lastSentText = text;
        _messageController.clear();
        setState(() => _messages.add(sent));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (e.toString().contains('403') && widget.role == 'koordinator') {
        setState(() => _canSend = false);
      }
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
      builder:
          (context) => GlassBottomSheet(
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  SheetActionTile(
                    icon: CupertinoIcons.photo_on_rectangle,
                    title: 'Pilih dari galeri',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  SheetActionTile(
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

    setState(() => _isUploadingImage = true);

    try {
      final sent = await ChatService.sendImageMessage(
        roomId: widget.roomId,
        role: widget.role,
        imagePath: picked.path,
        currentUserId: _currentUserId,
        message: _messageController.text.trim(),
      );

      if (sent != null) {
        _messageController.clear();
        setState(() => _messages.add(sent));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
      final list = await ChatService.fetchEtalaseList();
      if (mounted) {
        setState(() {
          _etalaseLayanan = list;
          _isLoadingEtalase = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEtalase = false;
          _etalaseError = 'Gagal memuat etalase: $e';
        });
      }
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
      builder:
          (_) => EtalaseBottomSheet(
            isLoading: _isLoadingEtalase,
            error: _etalaseError,
            items: _etalaseLayanan,
            onItemSelected: (item) => _sendEtalase(item.id),
          ),
    );
  }

  Future<void> _sendEtalase(int layananId) async {
    setState(() => _isSending = true);
    try {
      final sent = await ChatService.sendEtalase(
        roomId: widget.roomId,
        layananId: layananId,
        currentUserId: _currentUserId,
      );
      if (sent != null && mounted) {
        setState(() => _messages.add(sent));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      _showSnack('Gagal mengirim etalase: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSending = false);
      }
    }
  }

  void _openTawarHargaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => TawarHargaBottomSheet(
            onSendTawar: (harga, catatan) => _sendTawarHarga(harga, catatan),
          ),
    );
  }

  Future<bool> _sendTawarHarga(String harga, String? catatan) async {
    if (_isSending || _isUploadingImage) return false;
    if (harga.trim().isEmpty) {
      _showSnack('Nominal tawaran tidak boleh kosong.');
      return false;
    }

    setState(() => _isSending = true);
    try {
      final sent = await ChatService.sendTawarHarga(
        roomId: widget.roomId,
        role: widget.role,
        harga: harga,
        currentUserId: _currentUserId,
        catatan: catatan,
      );

      if (sent != null) {
        _lastSendAt = DateTime.now();
        _lastSentText = sent.text;
        setState(() => _messages.add(sent));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return true;
      }
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

    setState(() => _isSending = true);
    try {
      final sent = await ChatService.sendDealHarga(
        roomId: widget.roomId,
        role: widget.role,
        nominal: nominal,
        currentUserId: _currentUserId,
      );

      if (sent != null) {
        _lastSendAt = DateTime.now();
        _lastSentText = sent.text;
        setState(() => _messages.add(sent));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return true;
      }
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
      _showSnack('Akses chat ditutup.');
      return;
    }

    final nominal = ChatDealHelper.extractNominal(msg.text);
    if (nominal == null) {
      _showSnack('Gagal membaca nominal dari pesan tawaran.');
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Konfirmasi Deal Harga'),
            content: Text(
              'Setujui penawaran ini dengan nominal Rp $nominal?\n'
              'Pesan [DEAL HARGA] akan dikirim otomatis.',
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Setujui'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _sendDealHarga(nominal);
    }
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
        builder:
            (_) => BuatOrderDariChatPage(
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dealState = DealState.compute(
      messages: _messages,
      negoEnabled: _negoEnabled,
    );

    _currentLayananIdFromChat = dealState.layananId;
    _dealHarga = dealState.dealHarga;

    final hasDeal = dealState.hasDeal;
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                  StatusPill(label: _statusLabel, color: _statusColor),
                  if (_negoEnabled && hasDeal && dealState.dealHargaDisplay != null) ...[
                    const SizedBox(height: 10),
                    DealBanner(label: dealState.dealHargaDisplay!),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ChatMessagesList(
                controller: _scrollController,
                messages: _messages,
                isLoading: _isLoading,
                error: _error,
                negoEnabled: _negoEnabled,
                hasDeal: hasDeal,
                role: widget.role,
                onApproveTawar: _approveTawarFromMessage,
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
            ChatInputComposer(
              controller: _messageController,
              isBlocked: _isCoordinatorBlocked,
              isSending: _isSending || _isUploadingImage,
              showEtalase: widget.role == 'pasien' && _negoEnabled,
              showTawar: widget.role == 'pasien' && _negoEnabled && !hasDeal,
              onEtalaseTap: _openEtalaseSheet,
              onTawarTap: _openTawarHargaSheet,
              onImageTap: _pickAndSendImage,
              onSendTap: _sendMessage,
              hintText:
                  _isCoordinatorBlocked
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
}
