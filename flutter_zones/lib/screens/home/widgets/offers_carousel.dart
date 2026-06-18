import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/zonez_colors.dart';
import '../../../models/zones_models.dart';
import '../../../providers/zones_data_provider.dart';
import '../../offers/offer_details_screen.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({
    super.key,
    required this.offers,
    required this.loungeName,
  });

  final List<OfferModel> offers;
  final String loungeName;

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openOfferDetails(OfferModel offer) {
    final price = context.read<ZonesDataProvider>().getOfferPrice(offer.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailsScreen(
          offer: offer,
          loungeName: widget.loungeName,
          finalPrice: price,
        ),
      ),
    );
  }

  int? _discountFor(OfferModel offer, double finalPrice) {
    final original = offer.originalPrice;
    if (original == null || original <= 0 || finalPrice >= original) return null;
    return ((1 - finalPrice / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العروض الحالية',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ZonezColors.neonPurple,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.offers.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final offer = widget.offers[index];
              final price =
                  context.read<ZonesDataProvider>().getOfferPrice(offer.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _OfferCard(
                  offer: offer,
                  discountPercent: _discountFor(offer, price),
                  onTap: () => _openOfferDetails(offer),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.offers.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 10 : 6,
              height: i == _currentPage ? 10 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentPage
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onTap,
    this.discountPercent,
  });

  final OfferModel offer;
  final VoidCallback onTap;
  final int? discountPercent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ZonezColors.neonPurple.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              offer.offerImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: ZonezColors.inputBg,
                child: const Icon(Icons.image, color: ZonezColors.textMuted, size: 40),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    ZonezColors.deepBlack.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (discountPercent != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: ZonezColors.neonGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'خصم $discountPercent%',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: ZonezColors.neonCyan),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'عرض التفاصيل',
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
