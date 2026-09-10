import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: HomeImmersiveHeroHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: CategoryIconsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: LandscapeBannerSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: HealthTipsCarousel()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: SquareBannerSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: PromoFullWidthSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: TestimonialsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }
}
