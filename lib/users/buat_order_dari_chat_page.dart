import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat.dart'
    show kBaseUrl; // atau pindahkan kBaseUrl ke file lain yg global

class BuatOrderDariChatPage extends StatefulWidget {
  final int layananId;
  final int roomId;
  final int kesepakatanHarga; // dalam rupiah

  const BuatOrderDariChatPage({
    Key? key,
    required this.layananId,
    required this.roomId,
    required this.kesepakatanHarga,
  }) : super(key: key);

  @override
  State<BuatOrderDariChatPage> createState() => _BuatOrderDariChatPageState();
}

class _BuatOrderDariChatPageState extends State<BuatOrderDariChatPage> {
  final _alamatController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kotaController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  XFile? _kondisiFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _alamatController.dispose();
    _kecamatanController.dispose();
    _kotaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (result != null) {
      setState(() => _selectedDate = result);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final result = await showTimePicker(context: context, initialTime: now);
    if (result != null) {
      setState(() => _selectedTime = result);
    }
  }

  Future<void> _pickKondisiImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => _kondisiFile = file);
    }
  }

 Future<void> _submitOrder() async {
  if (_isSubmitting) return;

  if (_selectedDate == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pilih tanggal & jam kunjungan.')),
    );
    return;
  }
  if (_alamatController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alamat lengkap wajib diisi.')),
    );
    return;
  }
  if (_kondisiFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto kondisi pasien wajib diupload.')),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login berakhir, silakan login ulang.')),
      );
      return;
    }

    final tanggalMulai =
        "${_selectedDate!.year.toString().padLeft(4, '0')}-"
        "${_selectedDate!.month.toString().padLeft(2, '0')}-"
        "${_selectedDate!.day.toString().padLeft(2, '0')}";

    final jamMulai =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:"
        "${_selectedTime!.minute.toString().padLeft(2, '0')}";

    final uri = Uri.parse('$kBaseUrl/pasien/order-layanan');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['layanan_id'] = widget.layananId.toString()
      ..fields['tanggal_mulai'] = tanggalMulai
      ..fields['jam_mulai'] = jamMulai
      ..fields['alamat_lengkap'] = _alamatController.text.trim()
      ..fields['kecamatan'] = _kecamatanController.text.trim()
      ..fields['kota'] = _kotaController.text.trim()
      ..fields['catatan_pasien'] = _catatanController.text.trim()
      ..fields['qty'] = '1'
      ..fields['kesepakatan_harga'] = widget.kesepakatanHarga.toString();

    // ⬇️ FIX: pakai bytes, bukan fromPath
    final bytes = await _kondisiFile!.readAsBytes();
    final fileName = _kondisiFile!.name;

    request.files.add(
      http.MultipartFile.fromBytes(
        'kondisi_pasien',
        bytes,
        filename: fileName,
      ),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 201) {
      final body = json.decode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil dibuat')),
      );
      Navigator.pop(context, body['data']);
    } else if (res.statusCode == 422) {
      final body = json.decode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validasi gagal: ${body['message'] ?? 'cek data'}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat order (${res.statusCode})')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final hargaDisplay =
        "Rp ${widget.kesepakatanHarga.toString()}"; // bisa diformat lebih bagus pakai NumberFormat

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Order Layanan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan harga
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga disepakati',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hargaDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Jadwal Kunjungan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _selectedDate == null
                            ? 'Pilih Tanggal'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Pilih Jam'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Alamat Kunjungan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _alamatController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Alamat lengkap pasien...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kecamatanController,
                      decoration: const InputDecoration(
                        hintText: 'Kecamatan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _kotaController,
                      decoration: const InputDecoration(
                        hintText: 'Kota',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Catatan untuk petugas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Misalnya: pasien sulit berjalan, alergi obat tertentu...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Foto kondisi pasien (wajib)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickKondisiImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Foto'),
                  ),
                  const SizedBox(width: 12),
                  if (_kondisiFile != null)
                    Text(
                      'Foto terpilih',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buat Order Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
