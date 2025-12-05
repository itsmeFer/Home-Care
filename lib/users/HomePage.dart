import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat/pasien_chat_list_page.dart';
import 'package:home_care/users/Menu.dart';
import 'package:home_care/users/layananPage.dart';
import 'package:home_care/users/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/users/lihatHistoriPemesanan.dart';

/// Palet warna home care (teal/medical)
class HCColor {
  static const primary = Color(0xFF0BA5A7); // teal
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: HCColor.bg,
      bottomNavigationBar: const HCBottomNav(currentIndex: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // HUB kartu utama: cepat daftar, vital, SOAP
            const SliverToBoxAdapter(child: _CareHubCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // Grid fitur medis (7 + More)
            SliverToBoxAdapter(child: _ServicesGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ================= PROMO SECTION ================
            SliverToBoxAdapter(child: _PromoCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(child: _PromoChipsRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _PromoDoubleBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _PromoGridFour()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Paket & Layanan Populer',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _PromoHorizontalList()),

            // ================= END PROMO ====================
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            // Banner edukasi/kampanye kesehatan
            SliverToBoxAdapter(child: _HealthBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Artikel & Edukasi Kesehatan',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // List horizontal artikel/fitur
            SliverToBoxAdapter(child: _HorizontalCards()),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({super.key});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String? _fotoProfilUrl;
  String? _nama;
  bool _isLoadingFoto = false;

  // samakan dengan baseUrl di ProfilePage
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  @override
  void initState() {
    super.initState();
    _loadProfileFoto();
  }

  Future<void> _loadProfileFoto() async {
    try {
      setState(() => _isLoadingFoto = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      if (body is! Map || body['success'] != true) return;

      final data = body['data'] ?? {};
      final pasien = data['pasien'] as Map<String, dynamic>?;
      final user = data['user'] as Map<String, dynamic>?;

      final rawFoto = pasien?['foto_profil_url'] ?? pasien?['foto_profil'];

      setState(() {
        _fotoProfilUrl = (rawFoto is String && rawFoto.isNotEmpty)
            ? rawFoto
            : null;
        _nama = pasien?['nama_lengkap'] ?? user?['name'];
      });
    } catch (e) {
      // debugPrint('Gagal load foto topbar: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initial = (_nama != null && _nama!.isNotEmpty)
        ? _nama![0].toUpperCase()
        : '?';

    return Container(
      color: HCColor.bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // kiri: logo kecil / icon
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/home_nobg.png'),
          ),
          const SizedBox(width: 10),

          // search bar
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 22, color: HCColor.textMuted),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _HintPager(
                      hints: [
                        'Cari pasien / No. RM',
                        'Input tanda vital terbaru',
                        'Tulis SOAP note kunjungan',
                        'Jadwalkan perawatan luka',
                        'Atur reminder obat pasien',
                      ],
                      changeEvery: Duration(seconds: 3),
                      animDuration: Duration(milliseconds: 600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // kanan: avatar profil yang bisa diklik ke ProfilePage
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            borderRadius: BorderRadius.circular(19),
            child: _isLoadingFoto
                ? const SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 19,
                    backgroundColor: HCColor.primary,
                    backgroundImage:
                        (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty)
                        ? NetworkImage(_fotoProfilUrl!)
                        : null,
                    child: (_fotoProfilUrl == null || _fotoProfilUrl!.isEmpty)
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Rotating hint text slide up/down
class _HintPager extends StatefulWidget {
  final List<String> hints;
  final Duration changeEvery;
  final Duration animDuration;

  const _HintPager({
    super.key,
    required this.hints,
    this.changeEvery = const Duration(seconds: 5),
    this.animDuration = const Duration(milliseconds: 500),
  });

  @override
  State<_HintPager> createState() => _HintPagerState();
}

class _HintPagerState extends State<_HintPager> {
  late final PageController _controller;
  Timer? _timer;
  late int _startPage;

  @override
  void initState() {
    super.initState();
    _startPage = widget.hints.length * 1000;
    _controller = PageController(initialPage: _startPage);
    _timer = Timer.periodic(widget.changeEvery, (_) {
      if (!mounted) return;
      _controller.nextPage(
        duration: widget.animDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: HCColor.textMuted, fontSize: 14);
    return ClipRect(
      child: SizedBox(
        height: 20,
        child: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          itemBuilder: (_, index) {
            final text = widget.hints[index % widget.hints.length];
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(text, overflow: TextOverflow.ellipsis, style: style),
            );
          },
        ),
      ),
    );
  }
}

/// =================== CARE HUB CARD ===================
class _CareHubCard extends StatelessWidget {
  const _CareHubCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HCColor.primary, HCColor.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: HCColor.primaryDark.withOpacity(.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header chip + ringkasan cepat
          Row(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital, size: 16, color: Colors.black87),
                    SizedBox(width: 6),
                    Text(
                      'Prima Care',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _GlassButton(label: 'Lihat tugas hari ini', onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),
          // Action utama
          const Row(
            children: [
              _ActionPill(icon: Icons.person_add, label: 'Daftar Pasien'),
              _ActionPill(icon: Icons.monitor_heart, label: 'Tanda Vital'),
              _ActionPill(icon: Icons.description, label: 'SOAP Notes'),
            ],
          ),
          const SizedBox(height: 10),
          // Quick stats
          Row(
            children: const [
              _MiniStat(title: 'Kunjungan', value: '3'),
              _MiniStat(title: 'Kontrol', value: '2'),
              _MiniStat(title: 'Reminder', value: '5'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6FAFA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: Colors.teal[700]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// GRID FITUR MEDIS (7 + More)
class _ServicesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_Service>[
      _Service('Rekam Medis', Icons.folder_shared),
      _Service('Tanda Vital', Icons.monitor_heart),
      _Service('SOAP Notes', Icons.description),
      _Service('Perawatan Luka', Icons.healing),
      _Service('Care Plan', Icons.checklist),
      _Service('Obat & Reminder', Icons.medication),
      _Service('Hasil Lab/Radio', Icons.science),
      _Service.more('More', Icons.apps),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HCColor.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 88,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (_, i) => _ServiceItem(item: items[i]),
      ),
    );
  }
}

class _Service {
  final String title;
  final IconData icon;
  final bool isMore;
  _Service(this.title, this.icon) : isMore = false;
  _Service.more(this.title, this.icon) : isMore = true;
}

class _ServiceItem extends StatelessWidget {
  final _Service item;
  const _ServiceItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (item.isMore) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuPage()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Buka: ${item.title}')));
        }
      },
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: HCColor.primaryDark),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// ======================== PROMO WIDGETS ========================

/// 1) Carousel besar dengan indikator
class _PromoCarousel extends StatefulWidget {
  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController();
  int _index = 0;
  final _items = const [
    (
      'Home Nursing 24/7',
      'Perawat datang ke rumah. Diskon 20% khusus pengguna baru.',
      'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/486cf63c-a911-4b9f-ade6-e1344d0d1cd9/MYNURZ_INDONESIA_HOMECARE_Website_Banner_Layanan+MyNurz_Perawat.jpg',
    ),
    (
      'Paket Cek Kesehatan',
      'Cek kolesterol + gula + asam urat mulai Rp199K',
      'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/cdf99563-edf2-43ce-87f0-cec1264f21fc/MYNURZ_INDONESIA_HOMECARE_Website_Banner_Layanan+MyNurz_Fisioterapi.jpg',
    ),
    (
      'Vaksin ke Rumah',
      'Jadwalkan vaksin flu / booster. Gratis biaya kunjungan!',
      'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/e7a25fee-e7a1-46a5-bcb2-7a61f0e7d96b/MYNURZ_INDONESIA_HOMECARE_Website_Banner_Keamanan+%26+Profesionalitas.jpg',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final (title, subtitle, url) = _items[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _index == i ? 18 : 6,
              decoration: BoxDecoration(
                color: _index == i ? HCColor.primary : Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 2) Row chips promo mini
class _PromoChipsRow extends StatelessWidget {
  final chips = const [
    ('Gratis Kunjungan', Icons.local_shipping_outlined),
    ('Diskon 20%', Icons.local_offer_outlined),
    ('Paket Keluarga', Icons.family_restroom),
    ('Langganan', Icons.autorenew),
  ];

  const _PromoChipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final (label, icon) = chips[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(.06),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: HCColor.primaryDark),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

/// 3) Dua banner berdampingan
class _PromoDoubleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        'Cek Kesehatan',
        'Mulai Rp199K',
        'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/1b55b409-66ab-472e-a397-3cc9f70018a6/MyNurz+Indonesia_Artikel_Perawatan+Homecare_+Solusi+Kesehatan+untuk+Berbagai+Jenis+Penyakit.jpg',
      ),
      (
        'Home Lab Test',
        'Hasil 1x24 jam',
        'https://blogs.insanmedika.co.id/wp-content/uploads/2020/03/design-promo-blog.png',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items
            .map(
              (e) => Expanded(
                child: Container(
                  height: 110,
                  margin: EdgeInsets.only(
                    right: e == items.first ? 6 : 0,
                    left: e == items.last ? 6 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(e.$3),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          e.$2,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// 4) Grid promo 2x2
class _PromoGridFour extends StatelessWidget {
  final items = const [
    (
      'Home Nursing',
      'Diskon 15%',
      'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/818e905b-d25e-448a-9928-98bdd07a9851/MyNurz+Indonesia_Artikel_5+Keuntungan+dan+Manfaat+Menggunakan+Layanan+Jasa+Perawat+Lansia.jpg',
    ),
    (
      'Kontrol Rutin',
      'Gratis konsultasi',
      'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/01abdd5c-9c37-4729-82c7-0e316d0d5a16/MyNurz+Indonesia_Artikel_Perawat+Infal_+Pahlawan+yang+Tetap+Siaga+di+Musim+Natal+dan+Tahun+Baru.jpg',
    ),
    (
      'Perawatan Luka',
      'Paket 3x visit',
      'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/eaa0f0a4-c40e-4247-9b37-6f05d51430c8/MyNurz+Indonesia_Artikel_Perawatan+Home+Care+di+Jaman+Digitalisasi_+Transformasi+dalam+Dunia+Kesehatan.jpg',
    ),
    (
      'Vaksin Di Rumah',
      'Cashback 10%',
      'https://pbs.twimg.com/media/FQILYI-WYAI2rr0?format=jpg&name=4096x4096',
    ),
  ];

  _PromoGridFour({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (_, i) {
          final (title, subtitle, url) = items[i];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(.05),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 5) List promo horizontal
class _PromoHorizontalList extends StatelessWidget {
  final items = const [
    (
      'Paket Diabetes Care',
      'Kontrol + lab + edukasi',
      'https://rscarolus.or.id/wp-content/uploads/2025/05/promo-homecare-04-scaled.jpg',
    ),
    (
      'Home Physiotherapy',
      'Diskon sesi pertama',
      'https://rscarolus.or.id/wp-content/uploads/2025/08/VAKSIN-KEMERDEKAAN.jpg',
    ),
    (
      'Pendamping Lansia',
      'Mulai 4 jam/hari',
      'https://rscarolus.or.id/wp-content/uploads/2025/08/Promo-homecare-ibu-bayi-serba-199-A5-02-scaled.jpg',
    ),
  ];

  const _PromoHorizontalList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final (title, subtitle, url) = items[i];
          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ====================== END PROMO WIDGETS ======================

/// BANNER EDUKASI
class _HealthBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        image: const DecorationImage(
          image: NetworkImage(
            'https://kensaras.com/wp-content/uploads/2023/11/homecare-website-scaled.jpg',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Cek tekanan darah & gula rutin ya!',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// LIST ARTIKEL HORIZONTAL (edukasi)
class _HorizontalCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Pemantauan Tanda Vital di Rumah',
        'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/b83fb68b-ff08-417a-8f16-8869a7a157e7/MyNurz-Indonesia-Artikel-Keunggulan+Menggunakan+Perawat+ICU+Home+Care.jpg',
      ),
      (
        'Panduan Perawatan Luka',
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQrN6ZPTMAfz2AsSHK0uvnqTPmkESmyH4TtWM_p4i5wwLQaE3dfhL6TkFo_mchtXcDPDNE&usqp=CAU',
      ),
      (
        'Kepatuhan Minum Obat',
        'https://images.squarespace-cdn.com/content/v1/62cf775ec34e394e0c312a3b/1758085884476-3XZFRKS1IQE20RA82US0/Cari+Perawat+Lansia+Bukan+Hanya+Murah+dan+Cepat%2C+Tapi+Kualitas+yang+Utama.png?format=750w',
      ),
    ];
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final title = items[i].$1;
          final url = items[i].$2;
          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// BOTTOM NAV (tanpa OrderDraft, langsung ke PilihLayananPage)
class HCBottomNav extends StatelessWidget {
  final int currentIndex;
  const HCBottomNav({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0BA5A7),
      unselectedItemColor: Colors.black54,
      onTap: (i) {
        if (i == 0) {
          // Tetap di Beranda (Home)
        } else if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PilihLayananPage()),
          );
        } else if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LihatHistoriPemesananPage(),
            ),
          );
        } else if (i == 3) {
          // 🔥 TAB CHAT → daftar chat pasien
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PasienChatListPage()),
          );
        }
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_turned_in),
          label: 'Pemesanan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_turned_in),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
      ],
    );
  }
}
