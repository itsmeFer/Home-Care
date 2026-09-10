class SearchHistoryItem {
  final int id;
  final String keyword;
  final int searchCount;
  final String? lastSearchedAt;

  const SearchHistoryItem({
    required this.id,
    required this.keyword,
    required this.searchCount,
    this.lastSearchedAt,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      keyword: json['keyword']?.toString() ?? '',
      searchCount:
          json['search_count'] is int
              ? json['search_count']
              : int.tryParse(json['search_count']?.toString() ?? '0') ?? 0,
      lastSearchedAt: json['last_searched_at']?.toString(),
    );
  }
}

class RecentViewedLayananItem {
  final int id;
  final int layananId;
  final String namaLayanan;
  final String? kategori;
  final String? deskripsi;
  final double hargaFix;
  final String? gambarUrl;
  final int viewCount;
  final String? lastViewedAt;

  const RecentViewedLayananItem({
    required this.id,
    required this.layananId,
    required this.namaLayanan,
    this.kategori,
    this.deskripsi,
    required this.hargaFix,
    this.gambarUrl,
    required this.viewCount,
    this.lastViewedAt,
  });

  factory RecentViewedLayananItem.fromJson(Map<String, dynamic> json) {
    return RecentViewedLayananItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      layananId:
          json['layanan_id'] is int
              ? json['layanan_id']
              : int.tryParse('${json['layanan_id']}') ?? 0,
      namaLayanan: json['nama_layanan']?.toString() ?? '',
      kategori: json['kategori']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
      hargaFix: double.tryParse(json['harga_fix']?.toString() ?? '0') ?? 0,
      gambarUrl: json['gambar_url']?.toString(),
      viewCount:
          json['view_count'] is int
              ? json['view_count']
              : int.tryParse('${json['view_count']}') ?? 0,
      lastViewedAt: json['last_viewed_at']?.toString(),
    );
  }
}
