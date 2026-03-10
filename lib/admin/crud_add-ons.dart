import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CrudAddOnsPage extends StatefulWidget {
  const CrudAddOnsPage({super.key});

  @override
  State<CrudAddOnsPage> createState() => _CrudAddOnsPageState();
}

class _CrudAddOnsPageState extends State<CrudAddOnsPage>
    with SingleTickerProviderStateMixin {
  // =====================
  // CONFIG
  // =====================
  final String baseUrl = "http://192.168.1.6:8000/api";

  // =====================
  // TAB
  // =====================
  late TabController _tab;

  // =====================
  // STATE: ADDONS
  // =====================
  bool loadingAddons = true;
  bool loadingCategoriesDropdown = true;

  List<dynamic> addons = [];
  List<dynamic> categoriesDropdown = [];

  String q = "";
  int? selectedCategoryId;
  int? filterActive; // null=all, 1=aktif, 0=nonaktif

  int perPage = 15;
  int currentPage = 1;
  int lastPage = 1;

  final TextEditingController searchCtrl = TextEditingController();

  // =====================
  // STATE: ADDON CATEGORIES CRUD
  // =====================
  bool loadingCat = true;
  List<dynamic> catItems = [];

  String catQ = "";
  int? catIsActive; // null/1/0
  int catPerPage = 15;
  int catPage = 1;
  int catLastPage = 1;

  final TextEditingController catSearchCtrl = TextEditingController();

  bool catReorderMode = false; // mode drag urutan

  // =====================
  // LIFECYCLE
  // =====================
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _initLoad();
  }

  @override
  void dispose() {
    _tab.dispose();
    searchCtrl.dispose();
    catSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    await Future.wait([
      _fetchCategoriesDropdown(), // dropdown add-ons (active)
      _fetchAddons(resetPage: true),
      _fetchCategoryCrud(resetPage: true), // list kategori untuk tab kategori
    ]);
  }

  // =====================
  // AUTH HEADER
  // =====================
  Future<Map<String, String>> _authHeaders({bool jsonContent = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token"); // sesuaikan key token kamu
    final headers = <String, String>{
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    if (jsonContent) headers["Content-Type"] = "application/json";
    return headers;
  }

  // =====================
  // API: Categories (Dropdown) - GET /admin/addon-categories/all
  // =====================
  Future<void> _fetchCategoriesDropdown() async {
    setState(() => loadingCategoriesDropdown = true);
    try {
      final uri = Uri.parse("$baseUrl/admin/addon-categories/all");
      final res = await http.get(uri, headers: await _authHeaders());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          categoriesDropdown = body["data"] ?? [];
        });
      } else {
        _toast("Gagal ambil kategori dropdown (${res.statusCode})");
      }
    } catch (e) {
      _toast("Error kategori dropdown: $e");
    } finally {
      if (mounted) setState(() => loadingCategoriesDropdown = false);
    }
  }

  // =====================
  // API: List Addons
  // =====================
  Future<void> _fetchAddons({bool resetPage = false}) async {
    if (resetPage) currentPage = 1;

    setState(() => loadingAddons = true);
    try {
      final params = <String, String>{
        "per_page": perPage.toString(),
        "page": currentPage.toString(),
      };
      if (q.trim().isNotEmpty) params["q"] = q.trim();
      if (selectedCategoryId != null)
        params["category_id"] = selectedCategoryId.toString();
      if (filterActive != null) params["is_active"] = filterActive.toString();

      final uri = Uri.parse(
        "$baseUrl/admin/addons",
      ).replace(queryParameters: params);
      final res = await http.get(uri, headers: await _authHeaders());

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body["data"] ?? {};
        setState(() {
          addons = data["data"] ?? [];
          currentPage = data["current_page"] ?? 1;
          lastPage = data["last_page"] ?? 1;
        });
      } else {
        _toast("Gagal ambil add-ons (${res.statusCode})");
      }
    } catch (e) {
      _toast("Error list add-ons: $e");
    } finally {
      if (mounted) setState(() => loadingAddons = false);
    }
  }

  // =====================
  // API: Toggle Addon
  // =====================
  Future<void> _toggleAddon(int id, bool newValue) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addons/$id/toggle");
      final res = await http.patch(
        uri,
        headers: await _authHeaders(),
        body: jsonEncode({"aktif": newValue}),
      );
      if (res.statusCode == 200) {
        _toast("Status berhasil diubah");
        await _fetchAddons();
      } else {
        _toast("Gagal toggle (${res.statusCode})");
      }
    } catch (e) {
      _toast("Error toggle: $e");
    }
  }

  // =====================
  // API: Delete Addon
  // =====================
  Future<void> _deleteAddon(int id) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addons/$id");
      final res = await http.delete(uri, headers: await _authHeaders());
      if (res.statusCode == 200) {
        _toast("Add-on dihapus");
        await _fetchAddons();
      } else {
        _toast("Gagal hapus (${res.statusCode})");
      }
    } catch (e) {
      _toast("Error hapus: $e");
    }
  }

  // =====================
  // API: CATEGORY CRUD (Tab Kategori)
  // GET /admin/addon-categories?q&is_active&per_page&page
  // =====================
  Future<void> _fetchCategoryCrud({bool resetPage = false}) async {
    if (resetPage) catPage = 1;
    setState(() => loadingCat = true);

    try {
      final params = <String, String>{
        "per_page": catPerPage.toString(),
        "page": catPage.toString(),
      };
      if (catQ.trim().isNotEmpty) params["q"] = catQ.trim();
      if (catIsActive != null) params["is_active"] = catIsActive.toString();

      final uri = Uri.parse(
        "$baseUrl/admin/addon-categories",
      ).replace(queryParameters: params);
      final res = await http.get(uri, headers: await _authHeaders());

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body["data"] ?? {};
        setState(() {
          catItems = data["data"] ?? [];
          catPage = data["current_page"] ?? 1;
          catLastPage = data["last_page"] ?? 1;
        });
      } else {
        _toast("Gagal ambil kategori (${res.statusCode})");
      }
    } catch (e) {
      _toast("Error list kategori: $e");
    } finally {
      if (mounted) setState(() => loadingCat = false);
    }
  }

  // POST /admin/addon-categories
  Future<void> _createCategory(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addon-categories");
      final res = await http.post(
        uri,
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      );
      final body = _safeJson(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        _toast(body?["message"] ?? "Kategori dibuat");
        await Future.wait([
          _fetchCategoryCrud(resetPage: true),
          _fetchCategoriesDropdown(),
        ]);
      } else {
        _toast(
          body?["message"]?.toString() ?? "Gagal create (${res.statusCode})",
        );
      }
    } catch (e) {
      _toast("Error create kategori: $e");
    }
  }

  // PUT /admin/addon-categories/{id}
  Future<void> _updateCategory(int id, Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addon-categories/$id");
      final res = await http.put(
        uri,
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      );
      final body = _safeJson(res.body);

      if (res.statusCode == 200) {
        _toast(body?["message"] ?? "Kategori diupdate");
        await Future.wait([_fetchCategoryCrud(), _fetchCategoriesDropdown()]);
      } else {
        _toast(
          body?["message"]?.toString() ?? "Gagal update (${res.statusCode})",
        );
      }
    } catch (e) {
      _toast("Error update kategori: $e");
    }
  }

  // DELETE /admin/addon-categories/{id}
  Future<void> _deleteCategory(int id) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addon-categories/$id");
      final res = await http.delete(uri, headers: await _authHeaders());
      final body = _safeJson(res.body);

      if (res.statusCode == 200) {
        _toast(body?["message"] ?? "Kategori dihapus");
        await Future.wait([
          _fetchCategoryCrud(resetPage: true),
          _fetchCategoriesDropdown(),
        ]);
      } else {
        // controller kamu kirim 422 kalau addons_count > 0
        _toast(
          body?["message"]?.toString() ?? "Gagal hapus (${res.statusCode})",
        );
      }
    } catch (e) {
      _toast("Error hapus kategori: $e");
    }
  }

  // PATCH /admin/addon-categories/{id}/toggle  body: {is_active: boolean}
  Future<void> _toggleCategory(int id, bool newValue) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addon-categories/$id/toggle");
      final res = await http.patch(
        uri,
        headers: await _authHeaders(),
        body: jsonEncode({"is_active": newValue}),
      );
      final body = _safeJson(res.body);

      if (res.statusCode == 200) {
        _toast(body?["message"] ?? "Status kategori diubah");
        await Future.wait([_fetchCategoryCrud(), _fetchCategoriesDropdown()]);
      } else {
        _toast(
          body?["message"]?.toString() ?? "Gagal toggle (${res.statusCode})",
        );
      }
    } catch (e) {
      _toast("Error toggle kategori: $e");
    }
  }

  // POST /admin/addon-categories/reorder  body: {items: [{id, sort_order}]}
  Future<void> _reorderCategoriesCommit() async {
    try {
      final uri = Uri.parse("$baseUrl/admin/addon-categories/reorder");
      final items = <Map<String, dynamic>>[];
      for (int i = 0; i < catItems.length; i++) {
        items.add({"id": catItems[i]["id"], "sort_order": i});
      }

      final res = await http.post(
        uri,
        headers: await _authHeaders(),
        body: jsonEncode({"items": items}),
      );
      final body = _safeJson(res.body);

      if (res.statusCode == 200) {
        _toast(body?["message"] ?? "Urutan kategori diupdate");
        await Future.wait([
          _fetchCategoryCrud(resetPage: true),
          _fetchCategoriesDropdown(),
        ]);
      } else {
        _toast(
          body?["message"]?.toString() ?? "Gagal reorder (${res.statusCode})",
        );
      }
    } catch (e) {
      _toast("Error reorder: $e");
    }
  }

  // =====================
  // Helpers
  // =====================
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Map<String, dynamic>? _safeJson(String s) {
    try {
      final v = jsonDecode(s);
      if (v is Map<String, dynamic>) return v;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _mediaUrl(String path) => "$baseUrl/media/$path";

  String _rupiah(num v) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(v);
  }

  String _formatRupiahInput(dynamic value) {
    final num val = num.tryParse(value.toString()) ?? 0;
    final formatter = NumberFormat.decimalPattern('id_ID');
    return formatter.format(val);
  }

  // =====================
  // UI: Dialog Create/Update Addon (punyamu)
  // =====================
  Future<void> _openAddonForm({Map<String, dynamic>? item}) async {
    final isEdit = item != null;

    final kodeAddon = isEdit ? (item["kode_addon"] ?? "") : "Auto-generate";

    final namaCtrl = TextEditingController(
      text: isEdit ? (item["nama_addon"] ?? "") : "",
    );
    final deskCtrl = TextEditingController(
      text: isEdit ? (item["deskripsi"] ?? "") : "",
    );

    final hargaCtrl = TextEditingController(
      text: isEdit ? _formatRupiahInput(item["harga_fix_raw"] ?? 0) : "",
    );

    int? catId = isEdit ? item["addon_category_id"] : null;
    bool isQtyEnabled = isEdit ? (item["is_qty_enabled"] == true) : true;
    bool aktif = isEdit ? (item["aktif"] == true) : true;

    bool removeGambar = false;
    XFile? pickedImage;

    final formKey = GlobalKey<FormState>();

    Future<http.Response> _submit() async {
      final hargaStr = hargaCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      final fields = <String, String>{
        "nama_addon": namaCtrl.text.trim(),
        "deskripsi": deskCtrl.text.trim(),
        "harga_fix": hargaStr.isEmpty ? "0" : hargaStr,
        "is_qty_enabled": isQtyEnabled ? "1" : "0",
        "aktif": aktif ? "1" : "0",
      };
      if (catId != null) fields["addon_category_id"] = catId.toString();

      final uri = Uri.parse(
        isEdit
            ? "$baseUrl/admin/addons/${item!["id"]}"
            : "$baseUrl/admin/addons",
      );

      final req = http.MultipartRequest("POST", uri);
      if (isEdit) req.fields["_method"] = "PUT";

      req.fields.addAll(fields);

      if (isEdit) {
        req.fields["remove_gambar"] = removeGambar ? "1" : "0";
      }

      if (pickedImage != null) {
        req.files.add(
          await http.MultipartFile.fromPath("gambar", pickedImage!.path),
        );
      }

      final headers = await _authHeaders(jsonContent: false);
      req.headers.addAll(headers);

      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setM) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit ? "Edit Add-on" : "Tambah Add-on",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        initialValue: kodeAddon,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: "Kode Add-on",
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          suffixIcon: const Tooltip(
                            message: "Kode otomatis dibuat oleh sistem",
                            child: Icon(Icons.info_outline),
                          ),
                        ),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nama Add-on",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v ?? "").trim().isEmpty
                            ? "Nama wajib diisi"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: deskCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Deskripsi (opsional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<int?>(
                        value: catId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text("Tanpa kategori"),
                          ),
                          ...categoriesDropdown.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c["id"],
                              child: Text("${c["name"]}"),
                            ),
                          ),
                        ],
                        onChanged: (v) => setM(() => catId = v),
                        decoration: const InputDecoration(
                          labelText: "Kategori",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: hargaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CurrencyInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: "Harga Fix",
                          border: OutlineInputBorder(),
                          prefixText: "Rp ",
                        ),
                        validator: (v) {
                          final val = (v ?? "").trim().replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          if (val.isEmpty) return "Harga wajib diisi";
                          final n = num.tryParse(val);
                          if (n == null || n < 0) return "Harga tidak valid";
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Qty bisa diubah?"),
                        subtitle: const Text(
                          "Jika OFF, qty dipaksa 1 saat dipilih pasien.",
                        ),
                        value: isQtyEnabled,
                        onChanged: (v) => setM(() => isQtyEnabled = v),
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Aktif"),
                        value: aktif,
                        onChanged: (v) => setM(() => aktif = v),
                      ),

                      const Divider(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Gambar (opsional)",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (file != null) {
                                setM(() {
                                  pickedImage = file;
                                  removeGambar = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text("Pilih"),
                          ),
                        ],
                      ),

                      if (pickedImage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("File: ${pickedImage!.name}"),
                        ),

                      if (isEdit &&
                          pickedImage == null &&
                          (item!["gambar"] != null))
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Hapus gambar saat ini"),
                          value: removeGambar,
                          onChanged: (v) => setM(() => removeGambar = v),
                        ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false))
                              return;

                            try {
                              final res = await _submit();
                              final body = _safeJson(res.body);

                              if (res.statusCode == 200 ||
                                  res.statusCode == 201) {
                                if (mounted) Navigator.pop(ctx);
                                _toast(body?["message"] ?? "Sukses");
                                await _fetchAddons();
                              } else {
                                final msg =
                                    body?["message"]?.toString() ??
                                    "Gagal (${res.statusCode})";
                                _toast(msg);
                              }
                            } catch (e) {
                              _toast("Error submit: $e");
                            }
                          },
                          child: Text(
                            isEdit ? "Simpan Perubahan" : "Tambah Add-on",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================
  // UI: Dialog Create/Update Category (SIMPLIFIED - NO ICON/COLOR INPUT)
  // =====================
  Future<void> _openCategoryForm({Map<String, dynamic>? item}) async {
    final isEdit = item != null;

    final nameCtrl = TextEditingController(
      text: isEdit ? (item["name"] ?? "") : "",
    );
    final descCtrl = TextEditingController(
      text: isEdit ? (item["description"] ?? "") : "",
    );

    bool isActive = isEdit ? (item["is_active"] == true) : true;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setM) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit
                                  ? "Edit Kategori Add-on"
                                  : "Tambah Kategori Add-on",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nama Kategori",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v ?? "").trim().isEmpty
                            ? "Nama wajib diisi"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: descCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Deskripsi (opsional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Aktif"),
                        value: isActive,
                        onChanged: (v) => setM(() => isActive = v),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false))
                              return;

                            final payload = <String, dynamic>{
                              "name": nameCtrl.text.trim(),
                              "description": descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              "is_active": isActive,
                              // icon & color = null (tidak dikirim)
                            };

                            Navigator.pop(ctx);

                            if (isEdit) {
                              await _updateCategory(item!["id"], payload);
                            } else {
                              await _createCategory(payload);
                            }
                          },
                          child: Text(
                            isEdit ? "Simpan Perubahan" : "Tambah Kategori",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add-ons & Kategori"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.extension_outlined), text: "Add-ons"),
            Tab(icon: Icon(Icons.category_outlined), text: "Kategori"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () async {
              await Future.wait([
                _fetchAddons(resetPage: true),
                _fetchCategoryCrud(resetPage: true),
                _fetchCategoriesDropdown(),
              ]);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Tambah (sesuai tab)",
            onPressed: () {
              if (_tab.index == 0) {
                _openAddonForm();
              } else {
                _openCategoryForm();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildTabAddons(), _buildTabCategories()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tab.index == 0) {
            _openAddonForm();
          } else {
            _openCategoryForm();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // =====================
  // TAB 1: ADDONS
  // =====================
  Widget _buildTabAddons() {
    return Column(
      children: [
        _buildAddonFilters(),
        Expanded(
          child: loadingAddons
              ? const Center(child: CircularProgressIndicator())
              : addons.isEmpty
              ? const Center(child: Text("Belum ada add-ons"))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: addons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildAddonCard(addons[i]),
                ),
        ),
        _buildAddonPagination(),
      ],
    );
  }

  Widget _buildAddonFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: "Cari kode/nama/desk...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchCtrl.clear();
                        setState(() => q = "");
                        _fetchAddons(resetPage: true);
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (v) {
              setState(() => q = v);
              _fetchAddons(resetPage: true);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Semua kategori"),
                    ),
                    ...categoriesDropdown.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c["id"],
                        child: Text("${c["name"]}"),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => selectedCategoryId = v);
                    _fetchAddons(resetPage: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: filterActive,
                  decoration: InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<int?>(value: null, child: Text("Semua")),
                    DropdownMenuItem<int?>(value: 1, child: Text("Aktif")),
                    DropdownMenuItem<int?>(value: 0, child: Text("Nonaktif")),
                  ],
                  onChanged: (v) {
                    setState(() => filterActive = v);
                    _fetchAddons(resetPage: true);
                  },
                ),
              ),
            ],
          ),
          if (loadingCategoriesDropdown)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text("Memuat kategori dropdown..."),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddonCard(dynamic a) {
    final bool aktif = a["aktif"] == true;
    final bool qtyEnabled = a["is_qty_enabled"] == true;

    final category = a["category"];
    final categoryName = category != null ? (category["name"] ?? "-") : "-";

    final gambar = a["gambar"];
    final priceFormatted =
        a["harga_fix_formatted"] ?? _rupiah(a["harga_fix"] ?? 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 68,
              height: 68,
              color: Colors.grey.shade100,
              child: gambar == null
                  ? Icon(Icons.extension_outlined, color: Colors.grey.shade500)
                  : Image.network(
                      _mediaUrl(gambar.toString()),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade500,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a["nama_addon"] ?? "-",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a["kode_addon"] ?? "-",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 6),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip("Kategori: $categoryName"),
                    _chip(priceFormatted),
                    _chip(qtyEnabled ? "Qty: ON" : "Qty: OFF"),
                    _chip(
                      aktif ? "Aktif" : "Nonaktif",
                      accent: aktif ? Colors.green : Colors.red,
                    ),
                  ],
                ),

                if ((a["deskripsi"] ?? "").toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    a["deskripsi"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    Switch(
                      value: aktif,
                      onChanged: (v) => _toggleAddon(a["id"], v),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "Edit",
                      onPressed: () =>
                          _openAddonForm(item: Map<String, dynamic>.from(a)),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: "Hapus",
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Hapus add-on?"),
                            content: const Text(
                              "Ini akan soft delete. Data transaksi yang sudah ada aman.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Hapus"),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _deleteAddon(a["id"]);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonPagination() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text("Page $currentPage / $lastPage"),
          const Spacer(),
          IconButton(
            onPressed: currentPage <= 1 || loadingAddons
                ? null
                : () async {
                    setState(() => currentPage -= 1);
                    await _fetchAddons();
                  },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: currentPage >= lastPage || loadingAddons
                ? null
                : () async {
                    setState(() => currentPage += 1);
                    await _fetchAddons();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // =====================
  // TAB 2: CATEGORIES CRUD
  // =====================
  Widget _buildTabCategories() {
    return Column(
      children: [
        _buildCategoryFilters(),
        _buildCategoryToolbar(),
        Expanded(
          child: loadingCat
              ? const Center(child: CircularProgressIndicator())
              : catItems.isEmpty
              ? const Center(child: Text("Belum ada kategori add-on"))
              : catReorderMode
              ? _buildCategoryReorderList()
              : _buildCategoryList(),
        ),
        _buildCategoryPagination(),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            controller: catSearchCtrl,
            decoration: InputDecoration(
              hintText: "Cari nama/slug/deskripsi...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: catQ.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        catSearchCtrl.clear();
                        setState(() => catQ = "");
                        _fetchCategoryCrud(resetPage: true);
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (v) {
              setState(() => catQ = v);
              _fetchCategoryCrud(resetPage: true);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: catIsActive,
                  decoration: InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<int?>(value: null, child: Text("Semua")),
                    DropdownMenuItem<int?>(value: 1, child: Text("Aktif")),
                    DropdownMenuItem<int?>(value: 0, child: Text("Nonaktif")),
                  ],
                  onChanged: (v) {
                    setState(() => catIsActive = v);
                    _fetchCategoryCrud(resetPage: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: catPerPage,
                  decoration: InputDecoration(
                    labelText: "Per halaman",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text("10")),
                    DropdownMenuItem(value: 15, child: Text("15")),
                    DropdownMenuItem(value: 25, child: Text("25")),
                    DropdownMenuItem(value: 50, child: Text("50")),
                  ],
                  onChanged: (v) {
                    setState(() => catPerPage = v ?? 15);
                    _fetchCategoryCrud(resetPage: true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              catReorderMode
                  ? "Mode Urutan: drag untuk atur sort_order"
                  : "Kelola kategori add-on",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            onPressed: loadingCat
                ? null
                : () {
                    setState(() => catReorderMode = !catReorderMode);
                  },
            icon: Icon(
              catReorderMode
                  ? Icons.check_circle_outline
                  : Icons.drag_indicator,
            ),
            label: Text(catReorderMode ? "Selesai" : "Urutkan"),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: loadingCat ? null : () => _openCategoryForm(),
            icon: const Icon(Icons.add),
            label: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: catItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCategoryCard(catItems[i]),
    );
  }

  Widget _buildCategoryReorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: catItems.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = catItems.removeAt(oldIndex);
          catItems.insert(newIndex, item);
        });
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(14),
          child: child,
        );
      },
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: loadingCat
                ? null
                : () async {
                    await _reorderCategoriesCommit();
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text("Simpan Urutan (reorder)"),
          ),
        ),
      ),
      itemBuilder: (_, i) {
        final c = catItems[i];
        return Container(
          key: ValueKey("cat_${c["id"]}"),
          margin: const EdgeInsets.only(bottom: 10),
          child: _buildCategoryCard(c, reorderHandle: true),
        );
      },
    );
  }

  Widget _buildCategoryCard(dynamic c, {bool reorderHandle = false}) {
    final bool active = c["is_active"] == true;
    final int addonsCount = (c["addons_count"] is int)
        ? c["addons_count"]
        : int.tryParse("${c["addons_count"]}") ?? 0;

    final String name = c["name"]?.toString() ?? "-";
    final String slug = c["slug"]?.toString() ?? "-";
    final String desc = c["description"]?.toString() ?? "";
    final String? icon = c["icon"]?.toString();
    final String? color = c["color"]?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty
                    ? name.trim().characters.first.toUpperCase()
                    : "?",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (reorderHandle)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.drag_handle),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  slug,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip("Add-ons: $addonsCount"),
                    if (icon != null && icon.trim().isNotEmpty)
                      _chip("Icon: $icon"),
                    if (color != null && color.trim().isNotEmpty)
                      _chip("Color: $color"),
                    _chip(
                      active ? "Aktif" : "Nonaktif",
                      accent: active ? Colors.green : Colors.red,
                    ),
                  ],
                ),

                if (desc.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    Switch(
                      value: active,
                      onChanged: (v) => _toggleCategory(c["id"], v),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "Edit",
                      onPressed: () =>
                          _openCategoryForm(item: Map<String, dynamic>.from(c)),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: "Hapus",
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Hapus kategori?"),
                            content: Text(
                              "Kategori ini akan dihapus permanen.\n\n"
                              "Jika masih dipakai oleh add-ons, API akan mengembalikan 422.\n"
                              "Saat ini addons_count = $addonsCount",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Hapus"),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _deleteCategory(c["id"]);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPagination() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text("Page $catPage / $catLastPage"),
          const Spacer(),
          IconButton(
            onPressed: catPage <= 1 || loadingCat
                ? null
                : () async {
                    setState(() => catPage -= 1);
                    await _fetchCategoryCrud();
                  },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: catPage >= catLastPage || loadingCat
                ? null
                : () async {
                    setState(() => catPage += 1);
                    await _fetchCategoryCrud();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // =====================
  // CHIP
  // =====================
  Widget _chip(String text, {Color? accent}) {
    final bg = (accent ?? Colors.grey.shade200).withOpacity(0.15);
    final fg = accent ?? Colors.grey.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (accent ?? Colors.grey.shade300).withOpacity(0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// =====================
// Currency Input Formatter
// =====================
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(
      newValue.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (number == null) return oldValue;

    final formatter = NumberFormat.decimalPattern('id_ID');
    final newText = formatter.format(number);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}