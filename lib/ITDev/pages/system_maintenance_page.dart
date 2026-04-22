import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ui_components.dart';

class SystemMaintenancePage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const SystemMaintenancePage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  State<SystemMaintenancePage> createState() => _SystemMaintenancePageState();
}

class _SystemMaintenancePageState extends State<SystemMaintenancePage> {
  // ✅ CONFIG (sama dengan login page kamu)
  static const String baseUrl = 'http://192.168.1.5:8000/api';

  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isActive = false;
  String _currentMessage = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  // ✅ Load token dari SharedPreferences (sama dengan login page kamu)
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token');
    
    if (_token != null && _token!.isNotEmpty) {
      await _loadStatus();
    } else {
      _showError('Token tidak ditemukan. Silakan login ulang.');
    }
  }

  Future<void> _loadStatus() async {
    if (_token == null || _token!.isEmpty) {
      _showError('Token tidak valid');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/it/maintenance/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final maintenanceData = data['data'];
          setState(() {
            _isActive = maintenanceData['is_active'] ?? false;
            _currentMessage = maintenanceData['message'] ?? '';
            _messageController.text = _currentMessage;
          });
        }
      } else {
        _showError('Gagal memuat status: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal memuat status: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _activate() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showError('Pesan maintenance wajib diisi!');
      return;
    }

    if (_token == null || _token!.isEmpty) {
      _showError('Token tidak valid');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/it/maintenance/activate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'message': message,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccess('Maintenance mode diaktifkan!');
          await _loadStatus();
        } else {
          _showError(data['message'] ?? 'Gagal mengaktifkan');
        }
      } else {
        _showError('Gagal mengaktifkan: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal mengaktifkan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deactivate() async {
    if (_token == null || _token!.isEmpty) {
      _showError('Token tidak valid');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/it/maintenance/deactivate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccess('Maintenance mode dimatikan!');
          await _loadStatus();
        } else {
          _showError(data['message'] ?? 'Gagal mematikan');
        }
      } else {
        _showError('Gagal mematikan: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal mematikan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'System Maintenance',
          subtitle: 'Mode down/up + banner message (IT & Direktur bypass).',
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          XCard(
            title: 'Maintenance Mode',
            subtitle: 'Kontrol akses sistem (IT & Direktur tetap bisa akses).',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ToggleRow(
                  title: 'Status Maintenance',
                  valueText: _isActive ? 'ACTIVE 🔴' : 'OFF ✅',
                  isActive: _isActive,
                ),
                const SizedBox(height: 16),

                Text(
                  'Pesan Banner Maintenance:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sistem sedang maintenance untuk update fitur baru...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (!_isActive)
                      ElevatedButton.icon(
                        onPressed: _activate,
                        icon: Icon(Icons.play_circle_outline),
                        label: Text('Aktifkan Maintenance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),

                    if (_isActive)
                      ElevatedButton.icon(
                        onPressed: _deactivate,
                        icon: Icon(Icons.stop_circle_outlined),
                        label: Text('Matikan Maintenance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),

                    OutlineButtonX(
                      icon: Icons.refresh,
                      label: 'Refresh Status',
                      onTap: _loadStatus,
                    ),
                  ],
                ),

                if (_isActive) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'User biasa tidak bisa akses. Hanya IT & Direktur yang bisa login.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String valueText;
  final bool isActive;

  const _ToggleRow({
    required this.title,
    required this.valueText,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.orange.shade300 : Color(0xFFE2E8F0),
        ),
        color: isActive ? Colors.orange.shade50 : Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive ? Colors.orange : Color(0xFFE2E8F0),
              ),
              color: Colors.white,
            ),
            child: Text(
              valueText,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.orange.shade700 : Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}