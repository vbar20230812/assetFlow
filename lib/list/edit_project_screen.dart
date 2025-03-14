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
  static final Logger logger = Logger('EditProjectScreen');
  final DatabaseService databaseService = DatabaseService();
  final formKey = GlobalKey<FormState>();
  
  // Basic project fields
  late TextEditingController nameController;
  late TextEditingController companyController;
  late TextEditingController projectLengthController;
  late TextEditingController currencyController;
  
  // Amount stage fields
  late TextEditingController amountController;
  late DateTime startDate;
  late DateTime firstPaymentDate;
  
  // Fee fields
  late TextEditingController nonRefundableFeeController;
  late TextEditingController nonRefundableFeeNoteController;
  late TextEditingController refundableFeeController;
  late TextEditingController refundableFeeNoteController;
  
  bool isLoading = false;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    logger.info('Edit Project Screen initialized for: ${widget.project.id}');
    
    // Initialize controllers for basic project fields
    nameController = TextEditingController(text: widget.project.name);
    companyController = TextEditingController(text: widget.project.company);
    projectLengthController = TextEditingController(text: widget.project.projectLengthMonths.toString());
    currencyController = TextEditingController(text: widget.project.currency);
    
    // Initialize controllers for amount stage fields
    amountController = TextEditingController(
      text: widget.project.investmentAmount > 0 
          ? widget.project.investmentAmount.toStringAsFixed(2) 
          : ""
    );
    startDate = widget.project.startDate;
    firstPaymentDate = widget.project.firstPaymentDate;
    
    // Initialize controllers for fee fields
    nonRefundableFeeController = TextEditingController(
      text: widget.project.nonRefundableFee > 0 
          ? widget.project.nonRefundableFee.toStringAsFixed(2) 
          : ""
    );
    nonRefundableFeeNoteController = TextEditingController(text: widget.project.nonRefundableFeeNote);
    refundableFeeController = TextEditingController(
      text: widget.project.refundableFee > 0 
          ? widget.project.refundableFee.toStringAsFixed(2) 
          : ""
    );
    refundableFeeNoteController = TextEditingController(text: widget.project.refundableFeeNote);
    
    // Add listeners to detect changes
    nameController.addListener(onFieldChanged);
    companyController.addListener(onFieldChanged);
    projectLengthController.addListener(onFieldChanged);
    currencyController.addListener(onFieldChanged);
    amountController.addListener(onFieldChanged);
    nonRefundableFeeController.addListener(onFieldChanged);
    nonRefundableFeeNoteController.addListener(onFieldChanged);
    refundableFeeController.addListener(onFieldChanged);
    refundableFeeNoteController.addListener(onFieldChanged);
  }

  @override
  void dispose() {
    nameController.dispose();
    companyController.dispose();
    projectLengthController.dispose();
    currencyController.dispose();
    amountController.dispose();
    nonRefundableFeeController.dispose();
    nonRefundableFeeNoteController.dispose();
    refundableFeeController.dispose();
    refundableFeeNoteController.dispose();
    super.dispose();
  }

  /// Called when any field changes to track if form has unsaved changes
  void onFieldChanged() {
    setState(() {
      hasChanges = true;
    });
  }

  /// Show confirmation dialog for navigation when changes exist
  void confirmNavigation() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Project'),
          leading: BackButton(
            onPressed: () {
              if (hasChanges) {
                confirmNavigation();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            // Save button
            TextButton.icon(
              onPressed: hasChanges && !isLoading ? saveProject : null,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        body: AssetFlowLoadingWidget(
          isLoading: isLoading,
          loadingText: 'Saving project...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project details section
                  buildSectionHeader('Project Details'),
                  buildTextField(
                    controller: nameController,
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
                  buildTextField(
                    controller: companyController,
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
                  buildTextField(
                    controller: projectLengthController,
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
                  buildTextField(
                    controller: currencyController,
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
                  buildSectionHeader('Investment Details'),
                  
                  // Investment amount
                  buildTextField(
                    controller: amountController,
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
                  buildDateField(
                    label: 'Project Start Date',
                    date: startDate,
                    onTap: () => selectDate(context, true),
                  ),
                  const SizedBox(height: 16),
                  
                  // First payment date
                  buildDateField(
                    label: 'First Payment Date',
                    date: firstPaymentDate,
                    onTap: () => selectDate(context, false),
                  ),
                  const SizedBox(height: 32),
                  
                  // Additional fee section
                  buildSectionHeader('Additional Fees (Optional)'),
                  
                  // Non-refundable fee
                  buildTextField(
                    controller: nonRefundableFeeController,
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
                  buildTextField(
                    controller: nonRefundableFeeNoteController,
                    label: 'Notes on Non-Refundable Fee',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Refundable fee
                  buildTextField(
                    controller: refundableFeeController,
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
                  buildTextField(
                    controller: refundableFeeNoteController,
                    label: 'Notes on Refundable Fee',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: hasChanges && !isLoading ? saveProject : null,
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
    );
  }

  /// Build a section header
  Widget buildSectionHeader(String title) {
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
  Widget buildTextField({
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
  Widget buildDateField({
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
  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? startDate : firstPaymentDate;
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
          startDate = picked;
          // If start date is after first payment date, update first payment date
          if (startDate.isAfter(firstPaymentDate)) {
            firstPaymentDate = startDate.add(const Duration(days: 30));
          }
        } else {
          firstPaymentDate = picked;
        }
        hasChanges = true;
      });
    }
  }

  /// Save project changes
  Future<void> saveProject() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    logger.info('Saving project changes for: ${widget.project.id}');
    setState(() {
      isLoading = true;
    });
    
    try {
      // Parse form values for basic project fields
      final name = nameController.text.trim();
      final company = companyController.text.trim();
      final projectLengthMonths = int.parse(projectLengthController.text);
      final currency = currencyController.text.trim();
      
      // Parse form values for amount stage fields
      final investmentAmount = double.tryParse(amountController.text) ?? 0.0;
      
      // Parse form values for fee fields
      final nonRefundableFee = double.tryParse(nonRefundableFeeController.text) ?? 0.0;
      final nonRefundableFeeNote = nonRefundableFeeNoteController.text.trim();
      final refundableFee = double.tryParse(refundableFeeController.text) ?? 0.0;
      final refundableFeeNote = refundableFeeNoteController.text.trim();
      
      // Prepare data to update
      final data = {
        'name': name,
        'company': company,
        'projectLengthMonths': projectLengthMonths,
        'currency': currency,
        'investmentAmount': investmentAmount,
        'startDate': startDate,
        'firstPaymentDate': firstPaymentDate,
        'nonRefundableFee': nonRefundableFee,
        'nonRefundableFeeNote': nonRefundableFeeNote,
        'refundableFee': refundableFee,
        'refundableFeeNote': refundableFeeNote,
        'updatedAt': DateTime.now(),
      };
      
      // Update in Firestore
      await databaseService.updateProject(widget.project.id, data);
      
      logger.info('Project updated successfully');
      
      if (mounted) {
        setState(() {
          isLoading = false;
          hasChanges = false;
        });
        
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate successful update
      }
    } catch (e) {
      logger.severe('Error updating project: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating project: $e')),
        );
      }
    }
  }
}