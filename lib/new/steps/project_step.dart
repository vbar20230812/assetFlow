import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../models/project.dart';
import '../../utils/theme_colors.dart';
import '../../utils/formatter_util.dart';

/// First step of the investment wizard for entering project details
class ProjectStep extends StatefulWidget {
  final Project project;
  final Function(Project) onProjectUpdated;

  const ProjectStep({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  @override
  _ProjectStepState createState() => _ProjectStepState();
}

class _ProjectStepState extends State<ProjectStep> {
  static final Logger _logger = Logger('ProjectStep');
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _lengthController;
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _logger.info('ProjectStep initialized');
    
    // Initialize controllers with existing values
    _nameController = TextEditingController(text: widget.project.name);
    _companyController = TextEditingController(text: widget.project.company);
    _lengthController = TextEditingController(
      text: widget.project.projectLengthMonths.toString()
    );
    _selectedCurrency = widget.project.currency;
    
    // Listen for changes and update the project
    _nameController.addListener(_updateProject);
    _companyController.addListener(_updateProject);
    _lengthController.addListener(_updateProject);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  /// Update the project based on form values
  void _updateProject() {
    int length = 0;
    try {
      length = int.parse(_lengthController.text);
    } catch (e) {
      // If parsing fails, use 0 or previous value
      length = widget.project.projectLengthMonths;
    }
    
    final updatedProject = widget.project.copyWith(
      name: _nameController.text,
      company: _companyController.text,
      projectLengthMonths: length,
      currency: _selectedCurrency,
    );
    
    widget.onProjectUpdated(updatedProject);
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
                'Project Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Step description
              const Text(
                'Enter the basic information about your investment project.',
                style: TextStyle(
                  fontSize: 16,
                  color: AssetFlowColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Project name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  hintText: 'e.g., Downtown Apartments',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Company field
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment),
                  hintText: 'e.g., Real Estate Ventures LLC',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Project length field
              TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(
                  labelText: 'Project Length (months)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'e.g., 24',
                  helperText: 'The expected duration of the project in months',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the project length';
                  }
                  
                  try {
                    final months = int.parse(value);
                    if (months <= 0) {
                      return 'Project length must be greater than 0';
                    }
                    if (months > 240) { // 20 years limit
                      return 'Project length cannot exceed 240 months (20 years)';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Currency selector
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Select the currency for this project',
                ),
                items: [
                  DropdownMenuItem(
                    value: 'GBP',
                    child: Row(
                      children: [
                        Text('£', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('British Pound (GBP)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'USD',
                    child: Row(
                      children: [
                        Text('\$', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('US Dollar (USD)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'EUR',
                    child: Row(
                      children: [
                        Text('€', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('Euro (EUR)'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurrency = value;
                      _updateProject();
                    });
                  }
                },
              ),
              
              // Preview of currency formatting
              if (_selectedCurrency.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    color: AssetFlowColors.primary.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AssetFlowColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Example: ${FormatterUtil.formatCurrency(50000, currencyCode: _selectedCurrency)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AssetFlowColors.primary,
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
}