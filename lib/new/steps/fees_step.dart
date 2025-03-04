import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../utils/theme_colors.dart';
import '../../utils/formatter_util.dart';

/// Fourth and final step of the investment wizard for entering fees information
class FeesStep extends StatefulWidget {
  final double nonRefundableFee;
  final String nonRefundableFeeNote;
  final double refundableFee;
  final String refundableFeeNote;
  final Function(double) onNonRefundableFeeUpdated;
  final Function(String) onNonRefundableFeeNoteUpdated;
  final Function(double) onRefundableFeeUpdated;
  final Function(String) onRefundableFeeNoteUpdated;

  const FeesStep({
    super.key,
    required this.nonRefundableFee,
    required this.nonRefundableFeeNote,
    required this.refundableFee,
    required this.refundableFeeNote,
    required this.onNonRefundableFeeUpdated,
    required this.onNonRefundableFeeNoteUpdated,
    required this.onRefundableFeeUpdated,
    required this.onRefundableFeeNoteUpdated,
  });

  @override
  _FeesStepState createState() => _FeesStepState();
}

class _FeesStepState extends State<FeesStep> {
  static final Logger _logger = Logger('FeesStep');
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nonRefundableFeeController;
  late TextEditingController _nonRefundableFeeNoteController;
  late TextEditingController _refundableFeeController;
  late TextEditingController _refundableFeeNoteController;

  @override
  void initState() {
    super.initState();
    _logger.info('FeesStep initialized');
    
    // Initialize controllers with existing values
    _nonRefundableFeeController = TextEditingController(
      text: widget.nonRefundableFee > 0 ? widget.nonRefundableFee.toString() : '',
    );
    _nonRefundableFeeNoteController = TextEditingController(
      text: widget.nonRefundableFeeNote,
    );
    _refundableFeeController = TextEditingController(
      text: widget.refundableFee > 0 ? widget.refundableFee.toString() : '',
    );
    _refundableFeeNoteController = TextEditingController(
      text: widget.refundableFeeNote,
    );
    
    // Add listeners to update parent widget when values change
    _nonRefundableFeeController.addListener(_updateNonRefundableFee);
    _nonRefundableFeeNoteController.addListener(_updateNonRefundableFeeNote);
    _refundableFeeController.addListener(_updateRefundableFee);
    _refundableFeeNoteController.addListener(_updateRefundableFeeNote);
  }

  @override
  void dispose() {
    _nonRefundableFeeController.dispose();
    _nonRefundableFeeNoteController.dispose();
    _refundableFeeController.dispose();
    _refundableFeeNoteController.dispose();
    super.dispose();
  }

  void _updateNonRefundableFee() {
    try {
      final fee = _nonRefundableFeeController.text.isEmpty
          ? 0.0
          : double.parse(_nonRefundableFeeController.text);
      widget.onNonRefundableFeeUpdated(fee);
    } catch (e) {
      // Handle parsing error
    }
  }

  void _updateNonRefundableFeeNote() {
    widget.onNonRefundableFeeNoteUpdated(_nonRefundableFeeNoteController.text);
  }

  void _updateRefundableFee() {
    try {
      final fee = _refundableFeeController.text.isEmpty
          ? 0.0
          : double.parse(_refundableFeeController.text);
      widget.onRefundableFeeUpdated(fee);
    } catch (e) {
      // Handle parsing error
    }
  }

  void _updateRefundableFeeNote() {
    widget.onRefundableFeeNoteUpdated(_refundableFeeNoteController.text);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title
              Text(
                'Investment Fees',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Step description
              Text(
                'Enter any fees associated with this investment.',
                style: TextStyle(
                  fontSize: 16,
                  color: AssetFlowColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Non-refundable fee section
              _buildSectionTitle(
                'Non-Refundable Fees',
                'These fees will not be returned at the end of the investment',
                Icons.money_off,
                AssetFlowColors.fees,
              ),
              const SizedBox(height: 16),
              // Non-refundable fee amount
              TextFormField(
                controller: _nonRefundableFeeController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final fee = double.parse(value);
                      if (fee < 0) {
                        return 'Fee cannot be negative';
                      }
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Non-refundable fee note
              TextFormField(
                controller: _nonRefundableFeeNoteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Administration fee, setup costs',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              
              // Refundable fee section
              _buildSectionTitle(
                'Refundable Fees',
                'These fees will be returned at the end of the investment',
                Icons.money,
                AssetFlowColors.primary,
              ),
              const SizedBox(height: 16),
              // Refundable fee amount
              TextFormField(
                controller: _refundableFeeController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final fee = double.parse(value);
                      if (fee < 0) {
                        return 'Fee cannot be negative';
                      }
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Refundable fee note
              TextFormField(
                controller: _refundableFeeNoteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Security deposit, escrow',
                ),
                maxLines: 2,
              ),
              
              // Fees summary
              const SizedBox(height: 32),
              _buildFeesSummary(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section title with description and icon
  Widget _buildSectionTitle(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AssetFlowColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a summary of all fees
  Widget _buildFeesSummary() {
    final nonRefundableFee = _nonRefundableFeeController.text.isEmpty
        ? 0.0
        : double.tryParse(_nonRefundableFeeController.text) ?? 0.0;
    
    final refundableFee = _refundableFeeController.text.isEmpty
        ? 0.0
        : double.tryParse(_refundableFeeController.text) ?? 0.0;
    
    final totalFees = nonRefundableFee + refundableFee;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fees Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AssetFlowColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Non-refundable fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Non-Refundable Fee',
                  style: TextStyle(
                    fontSize: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
                Text(
                  FormatterUtil.formatCurrency(nonRefundableFee),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AssetFlowColors.fees,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Refundable fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Refundable Fee',
                  style: TextStyle(
                    fontSize: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
                Text(
                  FormatterUtil.formatCurrency(refundableFee),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AssetFlowColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Total fees
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Fees',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AssetFlowColors.textPrimary,
                  ),
                ),
                Text(
                  FormatterUtil.formatCurrency(totalFees),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AssetFlowColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}