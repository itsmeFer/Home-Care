import 'package:home_care/features/orders/domain/addon_model.dart';

class OrderPricingCalculator {
  static double calculateSubtotal({
    required double basePrice,
    int quantity = 1,
  }) {
    if (basePrice < 0) return 0.0;
    if (quantity < 1) return basePrice;
    return basePrice * quantity;
  }

  static double calculateAddonsTotal(List<Addon> addons) {
    return addons.fold<double>(
      0.0,
      (sum, item) => sum + (item.hargaFix * item.qty),
    );
  }

  static double calculateTotal({
    required double basePrice,
    int quantity = 1,
    List<Addon> selectedAddons = const [],
    double distanceKm = 0.0,
    double ratePerKm = 0.0,
    double freeDistanceKm = 0.0,
    double discountAmount = 0.0,
  }) {
    final subtotal = calculateSubtotal(
      basePrice: basePrice,
      quantity: quantity,
    );
    final addonsTotal = calculateAddonsTotal(selectedAddons);

    double distanceFee = 0.0;
    if (distanceKm > freeDistanceKm && ratePerKm > 0) {
      distanceFee = (distanceKm - freeDistanceKm) * ratePerKm;
    }

    final total = subtotal + addonsTotal + distanceFee - discountAmount;
    return total < 0 ? 0.0 : total;
  }
}
