import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../models/plan.dart';
import '../models/project.dart'; // Add project model import
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart'; // Add this import

/// Dialog for adding or editing an investment plan
class PlanFormDialog extends StatefulWidget {
  final String title;
  final Plan plan;
  final Project project; // Add project parameter
  final int projectLength;
  final Function(Plan) onSave;

  const PlanFormDialog({
    super.key,
    required this.title,
    required this.plan,
    required this.project, // Add required project parameter
    required this.projectLength,
    required this.onSave,
  });

  @override
  _PlanFormDialogState createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<PlanFormDialog> {
  static final Logger _logger = Logger('PlanFormDialog');
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  // Text controllers for all fields
  late TextEditingController _nameController;
  late TextEditingController _minimalAmountController;
  late TextEditingController _lengthMonthsController;
  late TextEditingController _annualInterestController;
  late TextEditingController _exitInterestController;
  
  // Form values
  late ParticipationType _participationType;
  late PaymentDistribution _paymentDistribution;
  late bool _hasGuarantee;

  @override
  void initState() {
    super.initState();
    _logger.info('PlanFormDialog initialized');
    
    // Initialize controllers with string values without decimal points
    _nameController = TextEditingController(text: widget.plan.name);
    _minimalAmountController = TextEditingController(
      text: widget.plan.minimalAmount.toInt().toString() // Remove decimal
    );
    _lengthMonthsController = TextEditingController(text: widget.plan.lengthMonths.toString());
    _annualInterestController = TextEditingController(
      text: (widget.plan.annualInterest * 100).toStringAsFixed(2)
    );
    _exitInterestController = TextEditingController(
      text: (widget.plan.exitInterest * 100).toStringAsFixed(2)
    );
    
    // Initialize other form values
    _participationType = widget.plan.participationType;
    _paymentDistribution = widget.plan.paymentDistribution;
    _hasGuarantee = widget.plan.hasGuarantee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minimalAmountController.dispose();
    _lengthMonthsController.dispose();
    _annualInterestController.dispose();
    _exitInterestController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = FormatterUtil.getCurrencySymbol(widget.project.currency);
    
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite, // Make dialog wider
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the plan';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Participation type dropdown
                  DropdownButtonFormField<ParticipationType>(
                    value: _participationType,
                    decoration: const InputDecoration(
                      labelText: 'Participation Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ParticipationType.values.map((type) {
                      return DropdownMenuItem<ParticipationType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _participationType = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a participation type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Minimal amount field
                  TextFormField(
                    controller: _minimalAmountController,
                    decoration: InputDecoration(
                      labelText: 'Minimal Amount',
                      border: const OutlineInputBorder(),
                      prefixText: currencySymbol,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Only allow digits (no decimal)
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the minimal amount';
                      }
                      
                      try {
                        final amount = int.parse(value);
                        if (amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Length field
                  TextFormField(
                    controller: _lengthMonthsController,
                    decoration: InputDecoration(
                      labelText: 'Length (months)',
                      border: const OutlineInputBorder(),
                      helperText: 'Default from project: ${widget.projectLength} months',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the length';
                      }
                      
                      try {
                        final months = int.parse(value);
                        if (months <= 0) {
                          return 'Length must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Annual interest field
                  TextFormField(
                    controller: _annualInterestController,
                    decoration: const InputDecoration(
                      labelText: 'Annual Interest (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the annual interest';
                      }
                      
                      try {
                        final interest = double.parse(value);
                        if (interest < 0) {
                          return 'Interest cannot be negative';
                        }
                        if (interest > 100) {
                          return 'Interest cannot exceed 100%';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment distribution dropdown
                  DropdownButtonFormField<PaymentDistribution>(
                    value: _paymentDistribution,
                    decoration: const InputDecoration(
                      labelText: 'Payment Distribution',
                      border: OutlineInputBorder(),
                    ),
                    items: PaymentDistribution.values.map((type) {
                      return DropdownMenuItem<PaymentDistribution>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentDistribution = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a payment distribution';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Guarantee field
                  SwitchListTile(
                    title: const Text('Has Guarantee'),
                    subtitle: const Text('Does this plan have a guarantee?'),
                    value: _hasGuarantee,
                    activeColor: AssetFlowColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _hasGuarantee = value;
                      });
                    },
                  ),
                  
                  // Exit interest field (only for non-exit distributions)
                  if (_paymentDistribution != PaymentDistribution.exit)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        controller: _exitInterestController,
                        decoration: const InputDecoration(
                          labelText: 'Exit Interest (%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                          helperText: 'Additional interest paid at project exit',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the exit interest';
                          }
                          
                          try {
                            final interest = double.parse(value);
                            if (interest < 0) {
                              return 'Interest cannot be negative';
                            }
                            if (interest > 100) {
                              return 'Interest cannot exceed 100%';
                            }
                          } catch (e) {
                            return 'Please enter a valid number';
                          }
                          
                          return null;
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AssetFlowColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Save the plan and close the dialog
  void _savePlan() {
    if (_formKey.currentState?.validate() ?? false) {
      _logger.info('Saving plan');
      
      // Parse values properly
      final double minimalAmount = double.parse(_minimalAmountController.text);
      final int lengthMonths = int.parse(_lengthMonthsController.text);
      final double annualInterest = double.parse(_annualInterestController.text) / 100; // Convert from percentage to decimal
      final double exitInterest = _exitInterestController.text.isNotEmpty ? 
                                 double.parse(_exitInterestController.text) / 100 : 0.0;
      
      // Create updated plan with form values
      final updatedPlan = widget.plan.copyWith(
        name: _nameController.text.trim(),
        participationType: _participationType,
        minimalAmount: minimalAmount,
        maximalAmount: minimalAmount, // Set maximal same as minimal
        lengthMonths: lengthMonths,
        interestRate: annualInterest, // Set interest rate directly
        paymentDistribution: _paymentDistribution,
        hasGuarantee: _hasGuarantee,
        exitInterest: exitInterest,
      );
      
      // Call the onSave callback with the updated plan
      widget.onSave(updatedPlan);
      
      // Dialog is automatically closed by Navigator.pop in PlanFormDialog after save
    }
  }
}