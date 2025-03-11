import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../models/plan.dart';
import '../models/project.dart'; // Add Project model import
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../widgets/asset_flow_loading_widget.dart';

/// Screen to edit a plan's details
class PlanEditScreen extends StatefulWidget {
  final String projectId;
  final Plan plan;
  final Project project; // Add project parameter

  const PlanEditScreen({
    super.key,
    required this.projectId,
    required this.plan,
    required this.project, // Add required project parameter
  });

  @override
  State<PlanEditScreen> createState() => _PlanEditScreenState();
}

class _PlanEditScreenState extends State<PlanEditScreen> {
  static final Logger _logger = Logger('PlanEditScreen');
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  late TextEditingController _minimalAmountController;
  late TextEditingController _annualInterestController;
  late TextEditingController _exitInterestController;
  late TextEditingController _lengthMonthsController;
  
  // Form values
  late ParticipationType _participationType;
  late PaymentDistribution _paymentDistribution;
  late bool _isSelected;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _logger.info('PlanEditScreen initialized for plan: ${widget.plan.id}');
    
    // Initialize controllers with current plan values
    _minimalAmountController = TextEditingController(text: widget.plan.minimalAmount.toString());
    _annualInterestController = TextEditingController(text: widget.plan.annualInterest.toString());
    _exitInterestController = TextEditingController(text: widget.plan.exitInterest.toString());
    _lengthMonthsController = TextEditingController(text: widget.plan.lengthMonths.toString());
    
    // Initialize other form values
    _participationType = widget.plan.participationType;
    _paymentDistribution = widget.plan.paymentDistribution;
    _isSelected = widget.plan.isSelected;
    
    // Add listeners to detect changes
    _minimalAmountController.addListener(_onFieldChanged);
    _annualInterestController.addListener(_onFieldChanged);
    _exitInterestController.addListener(_onFieldChanged);
    _lengthMonthsController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    // Dispose controllers
    _minimalAmountController.dispose();
    _annualInterestController.dispose();
    _exitInterestController.dispose();
    _lengthMonthsController.dispose();
    super.dispose();
  }

  /// Called when any field changes to track if form has unsaved changes
  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Investment Plan'),
        actions: [
          // Save button
          TextButton.icon(
            onPressed: _hasChanges && !_isLoading ? _savePlan : null,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: AssetFlowLoadingWidget(
          isLoading: _isLoading,
          loadingText: 'Saving plan...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan type selection
                  _buildSectionHeader('Plan Type'),
                  _buildParticipationTypeSelector(),
                  const SizedBox(height: 24),
                  
                  // Financial details
                  _buildSectionHeader('Financial Details'),
                  _buildNumberField(
                    controller: _minimalAmountController,
                    label: 'Minimum Investment Amount',
                    prefix: FormatterUtil.getCurrencySymbol(widget.project.currency),
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _annualInterestController,
                    label: 'Annual Interest Rate',
                    suffix: '%',
                    validator: _validateInterestRate,
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _exitInterestController,
                    label: 'Exit Interest Rate',
                    suffix: '%',
                    validator: _validateInterestRate,
                  ),
                  const SizedBox(height: 24),
                  
                  // Plan duration
                  _buildSectionHeader('Plan Duration'),
                  _buildNumberField(
                    controller: _lengthMonthsController,
                    label: 'Length (months)',
                    validator: _validateLength,
                  ),
                  const SizedBox(height: 24),
                  
                  // Payment distribution
                  _buildSectionHeader('Payment Distribution'),
                  _buildPaymentDistributionSelector(),
                  const SizedBox(height: 24),
                  
                  // Selected status
                  _buildSectionHeader('Plan Status'),
                  SwitchListTile(
                    title: const Text('Selected Plan'),
                    subtitle: const Text('Is this the currently active plan?'),
                    value: _isSelected,
                    onChanged: (value) {
                      setState(() {
                        _isSelected = value;
                        _hasChanges = true;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges && !_isLoading ? _savePlan : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssetFlowColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a section header
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AssetFlowColors.textPrimary,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build a number input field
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }

  /// Build the participation type selector
  Widget _buildParticipationTypeSelector() {
    return Column(
      children: [
        for (final type in ParticipationType.values)
          RadioListTile<ParticipationType>(
            title: Text(type.displayName),
            value: type,
            groupValue: _participationType,
            activeColor: AssetFlowColors.getParticipationTypeColor(type.displayName),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _participationType = value;
                  _hasChanges = true;
                });
              }
            },
          ),
      ],
    );
  }

  /// Build the payment distribution selector
  Widget _buildPaymentDistributionSelector() {
    return Column(
      children: [
        for (final distribution in PaymentDistribution.values)
          RadioListTile<PaymentDistribution>(
            title: Text(_getPaymentDistributionLabel(distribution)),
            value: distribution,
            groupValue: _paymentDistribution,
            activeColor: AssetFlowColors.primary,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _paymentDistribution = value;
                  _hasChanges = true;
                });
              }
            },
          ),
      ],
    );
  }

  /// Get display label for payment distribution
  String _getPaymentDistributionLabel(PaymentDistribution distribution) {
    switch (distribution) {
      case PaymentDistribution.monthly:
        return 'Monthly payments';
      case PaymentDistribution.quarterly:
        return 'Quarterly payments';
      case PaymentDistribution.semiannual: // Changed from halfYearly to semiannual
        return 'Semi-annual payments';
      case PaymentDistribution.annual:
        return 'Annual payments';
      case PaymentDistribution.exit:
        return 'Payment at exit';
    }
  }

  /// Validate amount input
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    
    return null;
  }

  /// Validate interest rate input
  String? _validateInterestRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an interest rate';
    }
    
    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid number';
    }
    
    if (rate < 0) {
      return 'Interest rate cannot be negative';
    }
    
    if (rate > 100) {
      return 'Interest rate cannot exceed 100%';
    }
    
    return null;
  }

  /// Validate length input
  String? _validateLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a length';
    }
    
    final length = int.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    
    if (length <= 0) {
      return 'Length must be greater than zero';
    }
    
    return null;
  }

  /// Check if user wants to discard changes when trying to exit
  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Don't allow to leave
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Allow to leave
            },
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Save plan changes
  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _logger.info('Saving plan changes for: ${widget.plan.id}');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse form values
      final minimalAmount = double.parse(_minimalAmountController.text);
      final annualInterest = double.parse(_annualInterestController.text) / 100; // Convert to decimal
      final exitInterest = double.parse(_exitInterestController.text) / 100; // Convert to decimal
      final lengthMonths = int.parse(_lengthMonthsController.text);
      
      // Prepare data to update
      final data = {
        'minimalAmount': minimalAmount,
        'interestRate': annualInterest, // Use interestRate instead of annualInterest
        'exitInterest': exitInterest,
        'lengthMonths': lengthMonths,
        'participationType': _participationType.index, // Use index instead of toString()
        'paymentDistribution': _paymentDistribution.index, // Use index instead of toString()
        'isSelected': _isSelected,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Update in Firestore
      await _databaseService.updatePlan(widget.projectId, widget.plan.id, data);
      
      _logger.info('Plan updated successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
        
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _logger.severe('Error updating plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating plan: $e')),
        );
      }
    }
  }
}