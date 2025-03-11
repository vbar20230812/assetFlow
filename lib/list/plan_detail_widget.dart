import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';

/// Widget for displaying plan header with participation type and selection status
class PlanHeader extends StatelessWidget {
  final Plan plan;

  const PlanHeader({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color.fromRGBO(
              AssetFlowColors.getParticipationTypeColor(
                plan.participationType.displayName,
              ).red,
              AssetFlowColors.getParticipationTypeColor(
                plan.participationType.displayName,
              ).green,
              AssetFlowColors.getParticipationTypeColor(
                plan.participationType.displayName,
              ).blue,
              0.1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            plan.participationType.displayName,
            style: TextStyle(
              color: AssetFlowColors.getParticipationTypeColor(
                plan.participationType.displayName,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (plan.isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                AssetFlowColors.success.red,
                AssetFlowColors.success.green,
                AssetFlowColors.success.blue,
                0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AssetFlowColors.success,
                ),
                SizedBox(width: 4),
                Text(
                  'Selected',
                  style: TextStyle(
                    color: AssetFlowColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Widget for displaying plan details section
class PlanDetailsSection extends StatelessWidget {
  final Plan plan;

  const PlanDetailsSection({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    String paymentSchedule = '';
    switch (plan.paymentDistribution) {
      case PaymentDistribution.monthly:
        paymentSchedule = 'Monthly payments';
        break;
      case PaymentDistribution.quarterly:
        paymentSchedule = 'Quarterly payments';
        break;
      case PaymentDistribution.semiannual:  // Use semiannual instead of halfYearly
        paymentSchedule = 'Semi-annual payments';
        break;
      case PaymentDistribution.annual:
        paymentSchedule = 'Annual payments';
        break;
      case PaymentDistribution.exit:
        paymentSchedule = 'Payment at exit';
        break;
    }

    return Column(
      children: [
        PlanDetailItem(
          label: 'Minimum Investment',
          value: FormatterUtil.formatCurrency(plan.minimalAmount),
        ),
        PlanDetailItem(
          label: 'Annual Interest Rate',
          value: '${plan.annualInterest.toStringAsFixed(2)}%',
        ),
        PlanDetailItem(
          label: 'Length',
          value: '${plan.lengthMonths} months',
        ),
        PlanDetailItem(
          label: 'Payment Schedule',
          value: paymentSchedule,
        ),
        if (plan.paymentDistribution != PaymentDistribution.exit)
          PlanDetailItem(
            label: 'Exit Interest',
            value: '${plan.exitInterest.toStringAsFixed(2)}%',
          ),
      ],
    );
  }
}

/// Widget for displaying a single plan detail item
class PlanDetailItem extends StatelessWidget {
  final String label;
  final String value;

  const PlanDetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AssetFlowColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AssetFlowColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}