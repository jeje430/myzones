import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../providers/lounge_booking_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import '../../services/lounge_api_extension.dart';
import 'steps/booking_step_availability.dart';
import 'steps/booking_step_confirmation.dart';
import 'steps/booking_step_date.dart';
import 'steps/booking_step_package.dart';
import 'steps/booking_step_payment.dart';

class LoungeBookingFlowScreen extends StatefulWidget {
  const LoungeBookingFlowScreen({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeBookingFlowScreen> createState() => _LoungeBookingFlowScreenState();
}

class _LoungeBookingFlowScreenState extends State<LoungeBookingFlowScreen> {
  LoungeModel? _lounge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshPackages();
  }

  Future<void> _refreshPackages() async {
    try {
      final fresh = await LoungeDataStore.instance.refreshLounge(widget.lounge.id);
      if (!mounted) return;
      if (fresh.bookingsBlocked) {
        final message = fresh.bookingStop?.message ?? 'الحجوزات متوقفة مؤقتاً';
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ZonezColors.cardDark,
            title: Text('الحجز غير متاح', style: ZonezTypography.title(size: 16)),
            content: Text(message, style: ZonezTypography.body(size: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() {
        _lounge = fresh;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _lounge = widget.lounge;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: ZonezColors.neonPurple),
        ),
      );
    }

    final lounge = _lounge ?? widget.lounge;

    return ChangeNotifierProvider(
      create: (_) => LoungeBookingProvider()..init(lounge),
      child: const _LoungeBookingFlowBody(),
    );
  }
}

class _LoungeBookingFlowBody extends StatelessWidget {
  const _LoungeBookingFlowBody();

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<LoungeBookingProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('احجز الآن', style: ZonezTypography.title(size: 16)),
            Text(
              flow.lounge?.name ?? '',
              style: ZonezTypography.caption(size: 11),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            const CircuitBackground(),
            Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + kToolbarHeight),
                _StepIndicator(currentStep: flow.currentStep),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStep(context, flow),
                  ),
                ),
                if (flow.currentStep != BookingFlowStep.confirmation &&
                    flow.currentStep != BookingFlowStep.payment)
                  _BottomNavBar(flow: flow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, LoungeBookingProvider flow) {
    switch (flow.currentStep) {
      case BookingFlowStep.packageSelection:
        return BookingStepPackage(
          key: const ValueKey('step1'),
          lounge: flow.lounge!,
        );
      case BookingFlowStep.dateSelection:
        return const BookingStepDate(key: ValueKey('step2'));
      case BookingFlowStep.availability:
        return const BookingStepAvailability(key: ValueKey('step3'));
      case BookingFlowStep.payment:
        return const BookingStepPayment(key: ValueKey('step4'));
      case BookingFlowStep.confirmation:
        return const BookingStepConfirmation(key: ValueKey('step5'));
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final BookingFlowStep currentStep;

  @override
  Widget build(BuildContext context) {
    final stepIndex = currentStep.index;
    final labels = LoungeBookingProvider.stepLabels;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Row(
              children: List.generate(labels.length, (i) {
                final isCompleted = i < stepIndex;
                final isActive = i == stepIndex;
                final isLast = i == labels.length - 1;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _StepCircle(
                              index: i + 1,
                              isCompleted: isCompleted,
                              isActive: isActive,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ZonezTypography.caption(
                                size: 9,
                                weight: isActive || isCompleted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive || isCompleted
                                    ? ZonezColors.neonCyan
                                    : ZonezColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                gradient: isCompleted ? ZonezColors.neonGradient : null,
                                color: isCompleted
                                    ? null
                                    : ZonezColors.borderMuted,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isCompleted,
    required this.isActive,
  });

  final int index;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final active = isActive || isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? ZonezColors.neonGradient : null,
        color: active ? null : ZonezColors.inputBg,
        border: Border.all(
          color: active
              ? Colors.transparent
              : ZonezColors.borderMuted,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$index',
                style: ZonezTypography.caption(
                  size: 13,
                  weight: FontWeight.bold,
                  color: active ? Colors.white : ZonezColors.textMuted,
                ),
              ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.flow});

  final LoungeBookingProvider flow;

  bool _canProceed() {
    switch (flow.currentStep) {
      case BookingFlowStep.packageSelection:
        return flow.canProceedFromStep1;
      case BookingFlowStep.dateSelection:
        return flow.canProceedFromStep2;
      case BookingFlowStep.availability:
        return flow.canProceedFromStep3;
      case BookingFlowStep.payment:
        return flow.canProceedFromStep4;
      case BookingFlowStep.confirmation:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = flow.currentStep == BookingFlowStep.packageSelection;
    final isPayment = flow.currentStep == BookingFlowStep.payment;

    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: flow.previousStep,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('السابق', style: ZonezTypography.body(size: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZonezColors.neonPurple,
                  side: const BorderSide(color: ZonezColors.neonPurple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (!isFirst) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _canProceed() ? ZonezColors.neonGradient : null,
                color: _canProceed() ? null : ZonezColors.borderMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: _canProceed()
                    ? () async {
                        if (isPayment) {
                          await flow.confirmBooking();
                        } else {
                          flow.nextStep();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: flow.isConfirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isPayment ? 'تأكيد الحجز' : 'التالي',
                            style: ZonezTypography.title(
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          if (!isPayment) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
