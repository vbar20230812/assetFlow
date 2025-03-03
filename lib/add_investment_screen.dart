import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'investment_models.dart';
import 'investment_service.dart';
import 'widgets/asset_flow_loader.dart';


class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  AddInvestmentScreenState createState() => AddInvestmentScreenState();
}

class AddInvestmentScreenState extends State<AddInvestmentScreen> {
  static final Logger _logger = Logger('AddInvestmentScreen');
  final InvestmentService _investmentService = InvestmentService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Project details controllers
  final _projectNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  String _selectedCurrency = 'USD';
  final _investmentAmountController = TextEditingController();
  final _additionalFeesRefundableController = TextEditingController(text: '0');
  final _additionalFeesNonRefundableController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  
  // Date controllers
  DateTime _contractDate = DateTime.now();
  DateTime _firstPaymentDate = DateTime.now().add(Duration(days: 30));
  DateTime _exitDate = DateTime.now().add(Duration(days: 365 * 3)); // 3 years

  // Investment plans - now starting empty
  final List<InvestmentPlan> _investmentPlans = [];
  String? _selectedPlanId;
  InvestmentPlan? get _selectedPlan => _investmentPlans.firstWhere(
    (plan) => plan.planId == _selectedPlanId,
    orElse: () => throw Exception('No plan selected'),
  );
  
  // Current step in the stepper (now with 4 steps instead of 3)
  int _currentStep = 0;

  // For add plan form
  final _categoryController = TextEditingController();
  final _minimalAmountController = TextEditingController();
  final _periodMonthsController = TextEditingController();
  final _interestRateController = TextEditingController();
  String _selectedPaymentPeriod = 'quarter';
  final _annualInterestPerPeriodController = TextEditingController();

  @override
  void dispose() {
    _projectNameController.dispose();
    _companyNameController.dispose();
    _investmentAmountController.dispose();
    _additionalFeesRefundableController.dispose();
    _additionalFeesNonRefundableController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _minimalAmountController.dispose();
    _periodMonthsController.dispose();
    _interestRateController.dispose();
    _annualInterestPerPeriodController.dispose();
    super.dispose();
  }

  Future<void> _saveInvestment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_investmentPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one investment plan')),
      );
      return;
    }
    
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an investment plan')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Format dates
      final dateFormat = DateFormat('dd/MM/yyyy');
      final contractDate = dateFormat.format(_contractDate);
      final firstPaymentDate = dateFormat.format(_firstPaymentDate);
      final exitDate = dateFormat.format(_exitDate);
      
      // Create investment data
      final investmentData = {
        'projectName': _projectNameController.text,
        'companyName': _companyNameController.text,
        'currency': _selectedCurrency,
        'investPlans': _investmentPlans.map((plan) => plan.toMap()).toList(),
        'additionalFeesRefundable': int.parse(_additionalFeesRefundableController.text),
        'additionalFeesNonRefundable': int.parse(_additionalFeesNonRefundableController.text),
        'notes': _notesController.text,
        'dateOfContractSign': contractDate,
        'dateOfFirstPayment': firstPaymentDate,
        'dateOfExit': exitDate,
        'selectedInvestPlan': _selectedPlanId,
        'investmentAmount': int.parse(_investmentAmountController.text),
      };
      
      // Save to database
      await _investmentService.createInvestment(investmentData);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investment created successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _logger.severe('Error saving investment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save investment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addInvestmentPlan() {
    // Validate the form fields
    if (_categoryController.text.isEmpty ||
        _minimalAmountController.text.isEmpty ||
        _periodMonthsController.text.isEmpty ||
        _interestRateController.text.isEmpty ||
        _annualInterestPerPeriodController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all plan fields')),
      );
      return;
    }
    
    // Generate a unique plan ID
    final planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create automatic name based on category and payment period
    final category = _categoryController.text;
    final paymentPeriod = _formatPaymentPeriod(_selectedPaymentPeriod);
    final planName = '$paymentPeriod $category';
    
    // Create a new investment plan
    final newPlan = InvestmentPlan(
      planId: planId,
      planName: planName,
      category: category,
      minimalAmount: int.parse(_minimalAmountController.text),
      periodMonths: int.parse(_periodMonthsController.text),
      interest: int.parse(_interestRateController.text),
      plannedDistributions: PlannedDistribution(
        paymentPeriod: _selectedPaymentPeriod,
        annualInterestPerPeriod: double.parse(_annualInterestPerPeriodController.text),
      ),
    );
    
    // Add to the list
    setState(() {
      _investmentPlans.add(newPlan);
      // If this is the first plan, select it automatically
      _selectedPlanId ??= planId;
      
      // Clear the form fields
      _categoryController.clear();
      _minimalAmountController.clear();
      _periodMonthsController.clear();
      _interestRateController.clear();
      _annualInterestPerPeriodController.clear();
      
      // Close the bottom sheet
      Navigator.pop(context);
    });
  }

  // Predefined investment categories
final List<String> _investmentCategories = [
  'Limited Partner',
  'Lender',
  'Development',
  'Real Estate',
  'Private Equity',
  'Venture Capital',
  'Infrastructure',
  'Other'
];

void _showAddPlanBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Investment Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Dropdown for category selection
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Investment Category*',
                border: OutlineInputBorder(),
                hintText: 'Select an investment category',
              ),
              value: _categoryController.text.isNotEmpty 
                  ? _categoryController.text 
                  : null,
              items: _investmentCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryController.text = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an investment category';
                }
                return null;
              },
              isExpanded: true,
            ),
            SizedBox(height: 12),
            
            // Period (Months) field - moved to first stage
            TextField(
              controller: _periodMonthsController,
              decoration: InputDecoration(
                labelText: 'Investment Period (Months)*',
                border: OutlineInputBorder(),
                hintText: 'Enter total investment period',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minimalAmountController,
                    decoration: InputDecoration(
                      labelText: 'Minimal Investment Amount*',
                      border: OutlineInputBorder(),
                      hintText: 'Minimum investment required',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _interestRateController,
                    decoration: InputDecoration(
                      labelText: 'Interest Rate (%)*',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Payment Period Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Payment Period*',
                border: OutlineInputBorder(),
              ),
              value: _selectedPaymentPeriod,
              items: [
                DropdownMenuItem(value: 'quarter', child: Text('Quarterly')),
                DropdownMenuItem(value: 'half', child: Text('Semiannually')),
                DropdownMenuItem(value: 'yearly', child: Text('Annually')),
                DropdownMenuItem(value: 'exit', child: Text('At Exit')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPaymentPeriod = value!;
                });
              },
            ),
            
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _validateAndAddInvestmentPlan,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 55)), // Use 0 instead of double.infinity for width
                  child: Text('Add Plan'),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

void _validateAndAddInvestmentPlan() {
  // Comprehensive validation before adding an investment plan
  if (_categoryController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select an investment category')),
    );
    return;
  }

  if (_periodMonthsController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter investment period in months')),
    );
    return;
  }

  if (_minimalAmountController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter minimal investment amount')),
    );
    return;
  }

  if (_interestRateController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter interest rate')),
    );
    return;
  }

  // Rest of the existing _addInvestmentPlan logic remains the same
  _addInvestmentPlan();
}

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != initialDate) {
      setState(() {
        onDateSelected(picked);
      });
    }
  }
  
  // Helper to format payment period for plan name
  String _formatPaymentPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'quarter':
        return 'Quarterly';
      case 'half':
        return 'Semiannual';
      case 'yearly':
        return 'Annual';
      case 'exit':
        return 'Exit-based';
      default:
        return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Investment'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Step Indicator
                _buildStepIndicator(),
                
                // Main content - Step-specific
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: _buildCurrentStepContent(),
                  ),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AssetFlowLoader(
                      size: 80,
                      primaryColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Saving investment...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      color: Colors.grey[100],
      child: Row(
        children: [
          _buildStepButton('Project', 0, Icons.business),
          _buildStepDivider(),
          _buildStepButton('Plans', 1, Icons.description),
          _buildStepDivider(),
          _buildStepButton('Amount', 2, Icons.attach_money),
          _buildStepDivider(),
          _buildStepButton('Details', 3, Icons.calendar_today),
        ],
      ),
    );
  }
  
  Widget _buildStepButton(String label, int step, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: TextButton(
        onPressed: () {
          // For investment amount step, verify a plan is selected
          if (step == 2 && _selectedPlanId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select an investment plan first')),
            );
            return;
          }
          
          // Allow navigation to steps that have already been visited or the next step
          if (step <= _currentStep || step == _currentStep + 1) {
            setState(() {
              _currentStep = step;
            });
          } else {
            // Show message that previous steps need to be completed first
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please complete previous steps first')),
            );
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(8),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Theme.of(context).primaryColor : 
                      isCompleted ? Colors.green : Colors.grey[300],
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check, color: Colors.white)
                    : Icon(icon, color: isActive ? Colors.white : Colors.grey[600]),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepDivider() {
    return Container(
      width: 30,
      height: 1,
      color: Colors.grey[300],
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep -= 1;
                });
              },
              child: Text('Back'),
            )
          else
            SizedBox(), // Empty space to maintain layout
          
          ElevatedButton(            
            onPressed: () {
              if (_currentStep < 3) {
                // Validate current step
                if (_currentStep == 0) {
                  if (_projectNameController.text.isEmpty || 
                      _companyNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }
                } else if (_currentStep == 1) {
                  if (_investmentPlans.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please add at least one investment plan')),
                    );
                    return;
                  }
                  if (_selectedPlanId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an investment plan')),
                    );
                    return;
                  }
                } else if (_currentStep == 2) {
                  if (_investmentAmountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter investment amount')),
                    );
                    return;
                  }
                  
                  // Verify the amount meets the minimum requirement
                  try {
                    int amount = int.parse(_investmentAmountController.text);
                    if (amount < _selectedPlan!.minimalAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Investment amount must be at least $_selectedCurrency ${_selectedPlan!.minimalAmount}')),
                      );
                      return;
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid investment amount')),
                    );
                    return;
                  }
                }
                
                setState(() {
                  _currentStep += 1;
                });
              } else {
                _saveInvestment();
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(0, 55)),
            child: Text(_currentStep < 3 ? 'Continue' : 'Save Investment'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProjectDetailsStep();
      case 1:
        return _buildInvestmentPlansStep();
      case 2:
        return _buildInvestmentAmountStep();
      case 3:
        return _buildDatesAndFeesStep();
      default:
        return Container();
    }
  }

  Widget _buildProjectDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _projectNameController,
          decoration: InputDecoration(
            labelText: 'Project Name*',
            hintText: 'e.g., MultiFamily 1',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a project name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _companyNameController,
          decoration: InputDecoration(
            labelText: 'Company Name*',
            hintText: 'e.g., SDB',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a company name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Currency*',
            border: OutlineInputBorder(),
          ),
          value: _selectedCurrency,
          items: ['USD', 'EUR', 'GBP', 'ILS'].map((currency) {
            return DropdownMenuItem(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCurrency = value!;
            });
          },
        ),
        SizedBox(height: 16),
        Text(
          '* Required fields',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentPlansStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Investment Plans',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Define the available investment plans for this project. Each plan can have different terms, interest rates, and payment schedules.',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        if (_investmentPlans.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No investment plans added yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first investment plan by clicking the button below',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _investmentPlans.length,
            itemBuilder: (context, index) {
              final plan = _investmentPlans[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  title: Text(
                    plan.planName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${plan.category}'),
                      Text('Minimum: $_selectedCurrency ${plan.minimalAmount}'),
                      Text('Interest: ${plan.interest}% (${_formatPaymentPeriod(plan.plannedDistributions.paymentPeriod)})'),
                      Text('Term: ${plan.periodMonths} months'),
                    ],
                  ),
                  value: plan.planId,
                  groupValue: _selectedPlanId,
                  onChanged: (value) {
                    setState(() {
                      _selectedPlanId = value;
                    });
                  },
                  secondary: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[300]),
                    onPressed: () {
                      setState(() {
                        // If the deleted plan was selected, unselect it
                        if (_selectedPlanId == plan.planId) {
                          _selectedPlanId = null;
                        }
                        
                        // Remove the plan
                        _investmentPlans.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('Add Investment Plan'),
          onPressed: _showAddPlanBottomSheet,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
  
  // New step for investment amount
  Widget _buildInvestmentAmountStep() {
    // Safety check - should never happen due to navigation validation
    if (_selectedPlanId == null) {
      return Center(
        child: Text('Please select an investment plan first'),
      );
    }
    
    final selectedPlan = _selectedPlan!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Amount',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        
        // Selected plan summary
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Plan: ${selectedPlan.planName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              _buildPlanDetailRow('Category', selectedPlan.category),
              _buildPlanDetailRow('Interest Rate', '${selectedPlan.interest}%'),
              _buildPlanDetailRow('Payment Period', _formatPaymentPeriod(selectedPlan.plannedDistributions.paymentPeriod)),
              _buildPlanDetailRow('Term', '${selectedPlan.periodMonths} months'),
              _buildPlanDetailRow('Minimum Investment', '$_selectedCurrency ${selectedPlan.minimalAmount}'),
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Investment amount field
        Text(
          'How much would you like to invest?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _investmentAmountController,
          decoration: InputDecoration(
            labelText: 'Investment Amount*',
            hintText: 'Enter amount in $_selectedCurrency',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            helperText: 'Minimum: $_selectedCurrency ${selectedPlan.minimalAmount}',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an investment amount';
            }
            int? amount = int.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid number';
            }
            if (amount < selectedPlan.minimalAmount) {
              return 'Minimum investment for this plan is $_selectedCurrency ${selectedPlan.minimalAmount}';
            }
            return null;
          },
        ),
        
        SizedBox(height: 24),
        
        // Expected returns calculation
        if (_investmentAmountController.text.isNotEmpty && 
            int.tryParse(_investmentAmountController.text) != null)
          _buildExpectedReturnsCard(selectedPlan),
      ],
    );
  }
  
  Widget _buildPlanDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpectedReturnsCard(InvestmentPlan plan) {
    int amount = int.parse(_investmentAmountController.text);
    double totalInterest = plan.calculateTotalInterest(amount);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expected Returns',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Principal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$_selectedCurrency $amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$_selectedCurrency ${totalInterest.round()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Return',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$_selectedCurrency ${amount + totalInterest.round()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Based on ${plan.interest}% interest over ${plan.periodMonths} months',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesAndFeesStep() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Important Dates',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ListTile(
          title: Text('Contract Date'),
          subtitle: Text(dateFormat.format(_contractDate)),
          trailing: Icon(Icons.calendar_today),
          onTap: () => _selectDate(
            context, 
            _contractDate, 
            (date) => _contractDate = date
          ),
        ),
        ListTile(
          title: Text('First Payment Date'),
          subtitle: Text(dateFormat.format(_firstPaymentDate)),
          trailing: Icon(Icons.calendar_today),
          onTap: () => _selectDate(
            context, 
            _firstPaymentDate, 
            (date) => _firstPaymentDate = date
          ),
        ),
        ListTile(
          title: Text('Exit Date'),
          subtitle: Text(dateFormat.format(_exitDate)),
          trailing: Icon(Icons.calendar_today),
          onTap: () => _selectDate(
            context, 
            _exitDate, 
            (date) => _exitDate = date
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Additional Fees',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _additionalFeesRefundableController,
          decoration: InputDecoration(
            labelText: 'Refundable Fees',
            hintText: 'Enter amount in $_selectedCurrency',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _additionalFeesNonRefundableController,
          decoration: InputDecoration(
            labelText: 'Non-Refundable Fees',
            hintText: 'Enter amount in $_selectedCurrency',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        
        // Show total calculation
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              _buildSummaryRow(
                'Investment Amount', 
                '$_selectedCurrency ${_investmentAmountController.text}'
              ),
              _buildSummaryRow(
                'Refundable Fees', 
                '$_selectedCurrency ${_additionalFeesRefundableController.text}'
              ),
              _buildSummaryRow(
                'Non-Refundable Fees', 
                '$_selectedCurrency ${_additionalFeesNonRefundableController.text}'
              ),
              Divider(),
              _buildSummaryRow(
                'Total Initial Payment', 
                '$_selectedCurrency ${_calculateTotalInitialPayment()}',
                isBold: true,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Notes',
            hintText: 'Optional notes about this investment',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  String _calculateTotalInitialPayment() {
    int investmentAmount = int.tryParse(_investmentAmountController.text) ?? 0;
    int refundableFees = int.tryParse(_additionalFeesRefundableController.text) ?? 0;
    int nonRefundableFees = int.tryParse(_additionalFeesNonRefundableController.text) ?? 0;
    
    return (investmentAmount + refundableFees + nonRefundableFees).toString();
  }
}