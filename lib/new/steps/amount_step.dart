import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

import '../../models/plan.dart';
import '../../utils/theme_colors.dart';
import '../../utils/date_util.dart';
import '../../utils/formatter_util.dart';

/// Third step of the investment wizard for entering investment amount and dates
class AmountStep extends StatefulWidget {
  final List<Plan> plans;
  final Plan? selectedPlan;
  final double amount;
  final DateTime startDate;
  final DateTime firstPaymentDate;
  final Function(double) onAmountUpdated;
  final Function(DateTime) onStartDateUpdated;
  final Function(DateTime) onFirstPaymentDateUpdated;
  final Function(Plan) onPlanSelected;

  const AmountStep({
    super.key,
    required this.plans,
    required this.selectedPlan,
    required this.amount,
    required this.startDate,
    required this.firstPaymentDate,
    required this.onAmountUpdated,
    required this.onStartDateUpdated,
    required this.onFirstPaymentDateUpdated,
    required this.onPlanSelected,
  });

  @override
  _AmountStepState createState() => _AmountStepState();
}

class _AmountStepState extends State<AmountStep> {
  static final Logger _logger = Logger('AmountStep');
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _amountController;
  late DateTime _startDate;
  late DateTime _firstPaymentDate;
  late Plan? _selectedPlan;
  bool _showAmountWarning = false;

  @override
  void initState() {
    super.initState();
    _logger.info('AmountStep initialized');
    
    // Initialize controllers and values
    _amountController = TextEditingController(
      text: widget.amount > 0 ? widget.amount.toString() : '',
    );
    _startDate = widget.startDate;
    _firstPaymentDate = widget.firstPaymentDate;
    _selectedPlan = widget.selectedPlan;
    
    // Listen for changes in the amount
    _amountController.addListener(_updateAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Update the investment amount
  void _updateAmount() {
    try {
      final amount = double.parse(_amountController.text);
      widget.onAmountUpdated(amount);
      
      // Check if the amount meets the minimum requirement of the selected plan
      if (_selectedPlan != null) {
        setState(() {
          _showAmountWarning = amount < _selectedPlan!.minimalAmount;
        });
      }
    } catch (e) {
      // Handle parsing error
    }
  }

  /// Update the selected plan based on the investment amount
  void _updateSelectedPlanBasedOnAmount(double amount) {
    if (widget.plans.isEmpty) return;
    
    // Find the best plan for the given amount
    final eligiblePlans = widget.plans
        .where((plan) => amount >= plan.minimalAmount)
        .toList();
    
    if (eligiblePlans.isNotEmpty) {
      // Sort by annual interest rate (highest first)
      eligiblePlans.sort((a, b) => b.annualInterest.compareTo(a.annualInterest));
      
      final bestPlan = eligiblePlans.first;
      if (_selectedPlan != bestPlan) {
        setState(() {
          _selectedPlan = bestPlan;
        });
        widget.onPlanSelected(bestPlan);
      }
    }
  }

  /// Show date picker for selecting a date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _firstPaymentDate;
    final DateTime firstDate = isStartDate 
        ? DateTime.now() 
        : _startDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AssetFlowColors.primary,
              onPrimary: Colors.white,
              onSurface: AssetFlowColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          widget.onStartDateUpdated(picked);
          
          // Update first payment date based on start date and payment distribution
          if (_selectedPlan != null) {
            _updateFirstPaymentDate();
          }
        } else {
          _firstPaymentDate = picked;
          widget.onFirstPaymentDateUpdated(picked);
        }
      });
    }
  }

  /// Update the first payment date based on start date and payment distribution
  void _updateFirstPaymentDate() {
    if (_selectedPlan == null) return;
    
    DateTime newFirstPaymentDate;
    
    switch (_selectedPlan!.paymentDistribution) {
  case PaymentDistribution.monthly:
    newFirstPaymentDate = DateUtil.addMonths(_startDate, 1);
    break;
  case PaymentDistribution.quarterly:
    newFirstPaymentDate = DateUtil.addMonths(_startDate, 3);
    break;
  case PaymentDistribution.semiannual:  // Use semiannual instead of halfYearly
    newFirstPaymentDate = DateUtil.addMonths(_startDate, 6);
    break;
  case PaymentDistribution.annual:
    newFirstPaymentDate = DateUtil.addMonths(_startDate, 12);
    break;
  case PaymentDistribution.exit:
    // For exit distribution, add the project length to the start date
    newFirstPaymentDate = DateUtil.addMonths(_startDate, _selectedPlan!.lengthMonths);
    break;
}
    
    setState(() {
      _firstPaymentDate = newFirstPaymentDate;
    });
    widget.onFirstPaymentDateUpdated(newFirstPaymentDate);
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
              const Text(
                'Investment Amount',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Step description
              const Text(
                'Specify your investment amount and important dates.',
                style: TextStyle(
                  fontSize: 16,
                  color: AssetFlowColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Selected plan summary
              if (_selectedPlan != null)
                _buildSelectedPlanSummary(),
                
              const SizedBox(height: 24),
              
              // Investment amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Investment Amount',
                  border: const OutlineInputBorder(),
                  prefixText: '\$',
                  helperText: _selectedPlan != null
                      ? 'Minimum: ${FormatterUtil.formatCurrency(_selectedPlan!.minimalAmount)}'
                      : 'Please select a plan first',
                  errorText: _showAmountWarning && _selectedPlan != null
                      ? 'Amount is less than the minimum required'
                      : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  try {
                    final amount = double.parse(value);
                    _updateSelectedPlanBasedOnAmount(amount);
                  } catch (e) {
                    // Handle parsing error
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the investment amount';
                  }
                  
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (_selectedPlan != null && amount < _selectedPlan!.minimalAmount) {
                      return 'Amount must be at least ${FormatterUtil.formatCurrency(_selectedPlan!.minimalAmount)}';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Start date field
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Project Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateUtil.formatLongDate(_startDate),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AssetFlowColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // First payment date field
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'First Payment Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    helperText: 'Date when you expect to receive the first payment',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateUtil.formatLongDate(_firstPaymentDate),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AssetFlowColors.textPrimary,
                        ),
                      ),
                      if (_selectedPlan != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '(${_selectedPlan!.paymentDistribution.displayName} distribution)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AssetFlowColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Information about automatic date calculation
              if (_selectedPlan != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: AssetFlowColors.info.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AssetFlowColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AssetFlowColors.info,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'First payment date is calculated based on your selected plan\'s payment distribution type. You can adjust it if needed.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AssetFlowColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a summary card for the selected plan
  Widget _buildSelectedPlanSummary() {
    if (_selectedPlan == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AssetFlowColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plan type label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AssetFlowColors.getParticipationTypeColor(
                      _selectedPlan!.participationType.displayName,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedPlan!.participationType.displayName,
                    style: TextStyle(
                      color: AssetFlowColors.getParticipationTypeColor(
                        _selectedPlan!.participationType.displayName,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Selected indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AssetFlowColors.success.withOpacity(0.1),
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
            ),
            const SizedBox(height: 16),
            
            // Plan details in a grid
            Row(
              children: [
                Expanded(
                  child: _buildPlanDetailItem(
                    'Annual Interest',
                    '${_selectedPlan!.annualInterest.toStringAsFixed(2)}%',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildPlanDetailItem(
                    'Payment Type',
                    _selectedPlan!.paymentDistribution.displayName,
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPlanDetailItem(
                    'Min. Amount',
                    FormatterUtil.formatCurrency(_selectedPlan!.minimalAmount),
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildPlanDetailItem(
                    'Length',
                    '${_selectedPlan!.lengthMonths} months',
                    Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            
            // Change plan button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // Navigate back to the Plan step
                  // This would need to be handled by the parent widget
                  _logger.info('Change plan button pressed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Go back to the Plans step to change your selected plan')),
                  );
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Plan'),
                style: TextButton.styleFrom(
                  foregroundColor: AssetFlowColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a detail item for the plan summary
  Widget _buildPlanDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AssetFlowColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AssetFlowColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}