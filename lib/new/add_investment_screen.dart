import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../services/database_service.dart';
import '../models/project.dart';
import '../models/plan.dart';
import '../utils/theme_colors.dart';
import '../widgets/asset_flow_loading_widget.dart';
import 'steps/project_step.dart';
import 'steps/plan_step.dart';
import 'steps/amount_step.dart';
import 'steps/fees_step.dart';
import '../list/assets_list_screen.dart';

/// Wizard screen for adding a new investment
class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  _AddInvestmentScreenState createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  static final Logger _logger = Logger('AddInvestmentScreen');
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Data for each step
  late Project _project;
  final List<Plan> _plans = [];
  Plan? _selectedPlan;
  double _investmentAmount = 0;
  DateTime _startDate = DateTime.now();
  DateTime _firstPaymentDate = DateTime.now();
  double _nonRefundableFee = 0;
  String _nonRefundableFeeNote = '';
  double _refundableFee = 0;
  String _refundableFeeNote = '';

  // Step titles for the progress indicator
  final List<String> _stepTitles = [
    'Project',
    'Plans',
    'Amount',
    'Fees',
  ];

  @override
  void initState() {
    super.initState();
    _logger.info('AddInvestmentScreen initialized');
    
    // Initialize project with default values
    _project = Project.create(
      name: '',
      company: '',
      projectLengthMonths: 12,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Investment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmCancel,
          ),
        ),
        body: AssetFlowLoadingWidget(
          isLoading: _isLoading,
          loadingText: 'Saving investment...',
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Step content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    // Project step
                    ProjectStep(
                      project: _project,
                      onProjectUpdated: (project) {
                        setState(() {
                          _project = project;
                        });
                      },
                    ),
                    
                    // Plan step
                    PlanStep(
                      projectId: _project.id,
                      project: _project, // Add this line
                      projectLength: _project.projectLengthMonths,
                      plans: _plans,
                      selectedPlan: _selectedPlan,
                      onPlanAdded: (plan) {
                        setState(() {
                          _plans.add(plan);
                        });
                      },
                      onPlanUpdated: (plan) {
                        setState(() {
                          final index = _plans.indexWhere((p) => p.id == plan.id);
                          if (index != -1) {
                            _plans[index] = plan;
                          }
                        });
                      },
                      onPlanDeleted: (plan) {
                        setState(() {
                          _plans.removeWhere((p) => p.id == plan.id);
                          if (_selectedPlan?.id == plan.id) {
                            _selectedPlan = null;
                          }
                        });
                      },
                      onPlanSelected: (plan) {
                        setState(() {
                          _selectedPlan = plan;
                        });
                      },
                    ),
                    
                    // Amount step
                    AmountStep(
                      plans: _plans,
                      selectedPlan: _selectedPlan,
                      amount: _investmentAmount,
                      startDate: _startDate,
                      firstPaymentDate: _firstPaymentDate,
                      onAmountUpdated: (amount) {
                        setState(() {
                          _investmentAmount = amount;
                        });
                      },
                      onStartDateUpdated: (date) {
                        setState(() {
                          _startDate = date;
                        });
                      },
                      onFirstPaymentDateUpdated: (date) {
                        setState(() {
                          _firstPaymentDate = date;
                        });
                      },
                      onPlanSelected: (plan) {
                        setState(() {
                          _selectedPlan = plan;
                        });
                      },
                    ),
                    
                    // Fees step
                    FeesStep(
                      nonRefundableFee: _nonRefundableFee,
                      nonRefundableFeeNote: _nonRefundableFeeNote,
                      refundableFee: _refundableFee,
                      refundableFeeNote: _refundableFeeNote,
                      onNonRefundableFeeUpdated: (fee) {
                        setState(() {
                          _nonRefundableFee = fee;
                        });
                      },
                      onNonRefundableFeeNoteUpdated: (note) {
                        setState(() {
                          _nonRefundableFeeNote = note;
                        });
                      },
                      onRefundableFeeUpdated: (fee) {
                        setState(() {
                          _refundableFee = fee;
                        });
                      },
                      onRefundableFeeNoteUpdated: (note) {
                        setState(() {
                          _refundableFeeNote = note;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the progress indicator for the wizard
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Row(
            children: [
              // Step indicator
              GestureDetector(
                onTap: () => _navigateToStep(index),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AssetFlowColors.success
                        : isActive
                            ? AssetFlowColors.primary
                            : AssetFlowColors.background,
                    border: Border.all(
                      color: isCompleted || isActive
                          ? Colors.transparent
                          : AssetFlowColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AssetFlowColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              
              // Step title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _stepTitles[index],
                  style: TextStyle(
                    color: isActive
                        ? AssetFlowColors.primary
                        : AssetFlowColors.textSecondary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              
              // Connector line
              if (index < _stepTitles.length - 1)
                Container(
                  width: 20,
                  height: 1,
                  color: isCompleted
                      ? AssetFlowColors.success
                      : AssetFlowColors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Build the navigation buttons
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Next or Save button
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep < _stepTitles.length - 1
                  ? _nextStep
                  : _saveInvestment,
              child: Text(_currentStep < _stepTitles.length - 1 ? 'Next' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to a specific step
  void _navigateToStep(int step) {
    // Only allow navigation to previous steps or the next available step
    if (step <= _currentStep || step == _currentStep + 1) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  /// Move to the previous step
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  /// Move to the next step
  void _nextStep() {
    // Validate current step before proceeding
    if (_validateCurrentStep()) {
      if (_currentStep < _stepTitles.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
  }

  /// Validate the current step
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Project step
        if (_project.name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project name is required')),
          );
          return false;
        }
        if (_project.company.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company name is required')),
          );
          return false;
        }
        if (_project.projectLengthMonths <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project length must be greater than 0')),
          );
          return false;
        }
        return true;
        
      case 1: // Plan step
        if (_plans.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one plan')),
          );
          return false;
        }
        return true;
        
      case 2: // Amount step
        if (_investmentAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Investment amount must be greater than 0')),
          );
          return false;
        }
        if (_selectedPlan == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a plan')),
          );
          return false;
        }
        if (_selectedPlan != null && _investmentAmount < _selectedPlan!.minimalAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Investment amount must be at least ${_selectedPlan!.minimalAmount}')),
          );
          return false;
        }
        return true;
        
      case 3: // Fees step
        // No validation needed for fees
        return true;
        
      default:
        return true;
    }
  }

  /// Save the investment
  Future<void> _saveInvestment() async {
    if (!_validateCurrentStep()) {
      return;
    }
    
    // Check if a plan is selected
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      // Navigate back to the plan step
      _navigateToStep(1);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _logger.info('Saving investment');
      
      // Save the project
      final projectId = await _databaseService.createProject(_project);
      _logger.info('Project saved with ID: $projectId');
      
      // Update the project ID
      _project = _project.copyWith(id: projectId);
      
      // Save the plans
      for (final plan in _plans) {
        final updatedPlan = plan.copyWith(
          projectId: projectId,
          isSelected: plan == _selectedPlan,
        );
        
        await _databaseService.addPlanToProject(projectId, updatedPlan);
        _logger.info('Plan saved for project: $projectId');
      }
      
      // TODO: Save the asset with fees and amount information
      
      _logger.info('Investment saved successfully');
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment saved successfully')),
        );
        
        // Navigate back to the assets list screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AssetsListScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      _logger.severe('Error saving investment: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving investment: $e')),
        );
      }
    }
  }

  /// Cancel the wizard
  void _confirmCancel() {
    _logger.info('Cancel confirmation requested');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel'),
        content: const Text('Are you sure you want to cancel? All changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    _confirmCancel();
    return false; // Don't allow default back button behavior
  }
}