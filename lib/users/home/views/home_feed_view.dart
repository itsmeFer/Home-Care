import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// Primary feed view for the patient dashboard.
/// Wraps all sections in a smooth CustomScrollView with pull-to-refresh.
class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  Key _feedKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _feedKey = UniqueKey();
    });
    // Micro-delay ensuring underlying futures and layout re-mount smoothly
    await Future.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF0BA5A7),
      child: KeyedSubtree(
        key: _feedKey,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: const [
            SliverToBoxAdapter(child: HomeImmersiveHeroHeader()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: CategoryIconsSection()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: LandscapeBannerSection()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: HealthTipsCarousel()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: SquareBannerSection()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: PromoFullWidthSection()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: TestimonialsSection()),
            SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }
}
