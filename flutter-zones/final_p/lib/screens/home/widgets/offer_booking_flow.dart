import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/zones_models.dart';
import '../../../providers/zones_data_provider.dart';
import '../../offers/offer_details_screen.dart';

/// Opens the offer details landing page (wizard starts via «احجز الآن»).
class OfferBookingFlow {
  OfferBookingFlow._();

  static void show(
    BuildContext context, {
    required OfferModel offer,
    required String loungeName,
    required double finalPrice,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailsScreen(
          offer: offer,
          loungeName: loungeName,
          finalPrice: finalPrice,
        ),
      ),
    );
  }

  static void showFromCarousel(
    BuildContext context,
    OfferModel offer,
    String loungeName,
  ) {
    final price = context.read<ZonesDataProvider>().getOfferPrice(offer.id);
    show(
      context,
      offer: offer,
      loungeName: loungeName,
      finalPrice: price,
    );
  }
}
