import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../models/plan.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../utils/date_util.dart';
import '../utils/formatter_util.dart';
import '../widgets/asset_flow_loading_widget.dart';

/// Screen to edit project details
class EditProjectScreen extends StatefulWidget {
  final Project project;
  final Plan? selectedPlan;

  const EditProjectScreen({
    super.key,
    required this.project,
    this.selectedPlan,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  static final Logger _logger = Logger('EditProjectScreen');
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  // Basic project fields
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _projectLengthController;
  late TextEditingController _currencyController;
  
  // Amount stage fields
  late TextEditingController _amountController;
  late DateTime _startDate;
  late DateTime _firstPaymentDate;
  
  // Fee fields
  late TextEditingController _nonRefundableFeeController;
  late TextEditingController _nonRefundableFeeNoteController;
  late TextEditingController _refundableFeeController;
  late TextEditingController _refundableFeeNoteController;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _logger.info('Edit Project Screen initialized for: ${widget.project.id}');
    
    // Initialize controllers for basic project fields
    _nameController = TextEditingController(text: widget.project.name);
    _companyController = TextEditingController(text: widget.project.company);
    _projectLengthController = TextEditingController(text: widget.project.projectLengthMonths.toString());
    _currencyController = TextEditingController(text: widget.project.currency);
    
    // Initialize controllers for amount stage fields
    _amountController = TextEditingController(
      text: widget.project.investmentAmount > 0 
          ? widget.project.investmentAmount.toStringAsFixed(2) 
          : ""
    );
    _startDate = widget.project.startDate;
    _firstPaymentDate = widget.project.firstPaymentDate;
    
    // Initialize controllers for fee fields
    _nonRefundableFeeController = TextEditingController(
      text: widget.project.nonRefundableFee > 0 
          ? widget.project.nonRefundableFee.toStringAsFixed(2) 
          : ""
    );
    _nonRefundableFeeNoteController = TextEditingController(text: widget.project.nonRefundableFeeNote);
    _refundableFeeController = TextEditingController(
      text: widget.project.refundableFee > 0 
          ? widget.project.refundableFee.toStringAsFixed(2) 
          : ""
    );
    _refundableFeeNoteController = TextEditingController(text: widget.project.refundableFeeNote);
    
    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
    _projectLengthController.addListener(_onFieldChanged);
    _currencyController.addListener(_onFieldChanged);
    _amountController.addListener(_onFieldChanged);
    _nonRefundableFeeController.addListener(_onFieldChanged);
    _nonRefundableFeeNoteController.addListener(_onFieldChanged);
    _refundableFeeController.addListener(_onFieldChanged);
    _refundableFeeNoteController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _projectLengthController.dispose();
    _currencyController.dispose();
    _amountController.dispose();
    _nonRefundableFeeController.dispose();
    _nonRefundableFeeNoteController.dispose();
    _refundableFeeController.dispose();
    _refundableFeeNoteController.dispose();
    super.dispose();
  }

  /// Called when any field changes to track if form has unsaved changes
  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  /// Mark form as changed when dates are updated
  //void _onDateChanged() {
  //  setState(() {
  //    _hasChanges = true;
  //  });
  //}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
        actions: [
          // Save button
          TextButton.icon(
            onPressed: _hasChanges && !_isLoading ? _saveProject : null,
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
          loadingText: 'Saving project...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project details section
                  _buildSectionHeader('Project Details'),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Project Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a project name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Company name
                  _buildTextField(
                    controller: _companyController,
                    label: 'Company Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a company name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Project length
                  _buildTextField(
                    controller: _projectLengthController,
                    label: 'Project Length (months)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the project length';
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
                  
                  // Currency
                  _buildTextField(
                    controller: _currencyController,
                    label: 'Currency',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a currency';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Investment details section
                  _buildSectionHeader('Investment Details'),
                  
                  // Investment amount
                  _buildTextField(
                    controller: _amountController,
                    label: 'Investment Amount',
                    prefix: FormatterUtil.getCurrencySymbol(widget.project.currency),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Amount is optional in edit mode
                      }
                      try {
                        final amount = double.parse(value);
                        if (amount < 0) {
                          return 'Amount cannot be negative';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Start date
                  _buildDateField(
                    label: 'Project Start Date',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 16),
                  
                  // First payment date
                  _buildDateField(
                    label: 'First Payment Date',
                    date: _firstPaymentDate,
                    onTap: () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 32),
                  
                  // Additional fee section
                  _buildSectionHeader('Additional Fees (Optional)'),
                  
                  // Non-refundable fee
                  _buildTextField(
                    controller: _nonRefundableFeeController,
                    label: 'Non-Refundable Fee',
                    prefix: FormatterUtil.getCurrencySymbol(widget.project.currency),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final amount = double.parse(value);
                          if (amount < 0) {
                            return 'Fee cannot be negative';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Non-refundable fee note
                  _buildTextField(
                    controller: _nonRefundableFeeNoteController,
                    label: 'Notes on Non-Refundable Fee',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Refundable fee
                  _buildTextField(
                    controller: _refundableFeeController,
                    label: 'Refundable Fee',
                    prefix: FormatterUtil.getCurrencySymbol(widget.project.currency),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final amount = double.parse(value);
                          if (amount < 0) {
                            return 'Fee cannot be negative';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Refundable fee note
                  _buildTextField(
                    controller: _refundableFeeNoteController,
                    label: 'Notes on Refundable Fee',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges && !_isLoading ? _saveProject : null,
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

  /// Build a text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: prefix,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }

  /// Build a date field
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateUtil.formatLongDate(date),
          style: const TextStyle(
            fontSize: 16,
            color: AssetFlowColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Show date picker for selecting a date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _firstPaymentDate;
    final DateTime firstDate = DateTime.now().subtract(const Duration(days: 365)); // Allow dates in the past for editing
    
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
          // If start date is after first payment date, update first payment date
          if (_startDate.isAfter(_firstPaymentDate)) {
            _firstPaymentDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _firstPaymentDate = picked;
        }
        _hasChanges = true;
      });
    }
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

  /// Save project changes
  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _logger.info('Saving project changes for: ${widget.project.id}');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse form values for basic project fields
      final name = _nameController.text.trim();
      final company = _companyController.text.trim();
      final projectLengthMonths = int.parse(_projectLengthController.text);
      final currency = _currencyController.text.trim();
      
      // Parse form values for amount stage fields
      final investmentAmount = double.tryParse(_amountController.text) ?? 0.0;
      
      // Parse form values for fee fields
      final nonRefundableFee = double.tryParse(_nonRefundableFeeController.text) ?? 0.0;
      final nonRefundableFeeNote = _nonRefundableFeeNoteController.text.trim();
      final refundableFee = double.tryParse(_refundableFeeController.text) ?? 0.0;
      final refundableFeeNote = _refundableFeeNoteController.text.trim();
      
      // Prepare data to update
      final data = {
        'name': name,
        'company': company,
        'projectLengthMonths': projectLengthMonths,
        'currency': currency,
        'investmentAmount': investmentAmount,
        'startDate': _startDate,
        'firstPaymentDate': _firstPaymentDate,
        'nonRefundableFee': nonRefundableFee,
        'nonRefundableFeeNote': nonRefundableFeeNote,
        'refundableFee': refundableFee,
        'refundableFeeNote': refundableFeeNote,
        'updatedAt': DateTime.now(),
      };
      
      // Update in Firestore
      await _databaseService.updateProject(widget.project.id, data);
      
      _logger.info('Project updated successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
        
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate successful update
      }
    } catch (e) {
      _logger.severe('Error updating project: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating project: $e')),
        );
      }
    }
  }
}