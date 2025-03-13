import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/project.dart';
import '../models/plan.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../utils/date_util.dart';
import '../widgets/asset_flow_loading_widget.dart';
import 'plan_detail_widget.dart';
import 'plan_form_dialog.dart';
import 'edit_project_screen.dart'; // Add this import

/// Screen that displays detailed information about a single asset/investment
class AssetDetailScreen extends StatefulWidget {
  final String projectId;

  const AssetDetailScreen({super.key, required this.projectId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  static final Logger _logger = Logger('AssetDetailScreen');
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  late Project _project;
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _logger.info('AssetDetailScreen initialized for project: ${widget.projectId}');
    _loadProjectData();
  }

  /// Load project and plans data
  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _project = await _databaseService.getProject(widget.projectId);

      // Listen for plans updates
      _databaseService.getProjectPlans(widget.projectId).listen((plans) {
        if (mounted) {
          setState(() {
            _plans = plans;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        _logger.severe('Error loading plans: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading plans: $error')),
          );
        }
      });
    } catch (e) {
      _logger.severe('Error loading project: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Investment Details')
            : Text(_project.name),
        actions: [
          // Archive/Unarchive button
          if (!_isLoading)
            IconButton(
              icon: Icon(_project.isArchived ? Icons.unarchive : Icons.archive),
              onPressed: _toggleArchiveStatus,
              tooltip: _project.isArchived ? 'Unarchive' : 'Archive',
            ),
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editProject,
            tooltip: 'Edit',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _confirmDeleteProject,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: AssetFlowLoadingWidget(
        isLoading: _isLoading,
        loadingText: 'Loading investment details...',
        child: _isLoading
            ? const SizedBox.shrink() // Will be covered by loading overlay
            : _buildProjectDetails(),
      ),
    );
  }

  /// Build the project details content
  Widget _buildProjectDetails() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Ensure scrolling is always enabled
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project overview section
          _buildProjectOverview(),
          
          const Divider(height: 32),
          
          // Plans section
          _buildPlansSection(),
          
          // Add some bottom padding for better scrolling
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build the project overview section
  /// Build the project overview section
/// Build the project overview section
Widget _buildProjectOverview() {
  return Container(
    padding: const EdgeInsets.all(16),
    color: AssetFlowColors.background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project name and archived badge if needed
        Row(
          children: [
            Expanded(
              child: Text(
                _project.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _project.isArchived
                      ? AssetFlowColors.textSecondary
                      : AssetFlowColors.primary,
                ),
              ),
            ),
            if (_project.isArchived)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Archived',
                  style: TextStyle(
                    fontSize: 12,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Project details
        // Company name
        _buildDetailItem(
          icon: Icons.business,
          label: 'Company',
          value: _project.company,
        ),
        
        // Project duration
        _buildDetailItem(
          icon: Icons.calendar_today,
          label: 'Project Duration',
          value: '${_project.projectLengthMonths} months',
        ),
        
        // Investment amount (instead of currency)
        if (_project.investmentAmount > 0)
          _buildDetailItem(
            icon: Icons.attach_money,
            label: 'Investment Amount',
            value: FormatterUtil.formatCurrency(_project.investmentAmount, currencyCode: _project.currency),
          ),
        
        // Project dates section
        if (_project.startDate.isAfter(DateTime(2020)))
          _buildDetailItem(
            icon: Icons.date_range,
            label: 'Start Date',
            value: DateUtil.formatLongDate(_project.startDate),
          ),
        
        if (_project.firstPaymentDate.isAfter(DateTime(2020)))
          _buildDetailItem(
            icon: Icons.payments,
            label: 'First Payment Date',
            value: DateUtil.formatLongDate(_project.firstPaymentDate),
          ),
        
        // Fee section
        if (_project.nonRefundableFee > 0)
          _buildDetailItem(
            icon: Icons.money_off,
            label: 'Non-Refundable Fee',
            value: FormatterUtil.formatCurrency(_project.nonRefundableFee, currencyCode: _project.currency),
          ),
        
        if (_project.nonRefundableFeeNote.isNotEmpty)
          _buildDetailItem(
            icon: Icons.note,
            label: 'Non-Refundable Fee Note',
            value: _project.nonRefundableFeeNote,
          ),
        
        if (_project.refundableFee > 0)
          _buildDetailItem(
            icon: Icons.attach_money,
            label: 'Refundable Fee',
            value: FormatterUtil.formatCurrency(_project.refundableFee, currencyCode: _project.currency),
          ),
        
        if (_project.refundableFeeNote.isNotEmpty)
          _buildDetailItem(
            icon: Icons.note,
            label: 'Refundable Fee Note',
            value: _project.refundableFeeNote,
          ),
      ],
    ),
  );
}

  /// Build a detail item with icon, label, and value
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AssetFlowColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }

  /// Build the plans section
  Widget _buildPlansSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Investment Plans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textPrimary,
                ),
              ),
              // Add plan button
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addPlan,
                tooltip: 'Add Plan',
                color: AssetFlowColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Plans list - use a limited height container if many plans are present
          _plans.isEmpty
              ? _buildEmptyPlansMessage()
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    // If many plans, limit height but ensure it's scrollable
                    maxHeight: _plans.length > 2 
                        ? MediaQuery.of(context).size.height * 0.5 
                        : double.infinity,
                  ),
                  child: ListView.builder(
                    // Use different physics based on number of plans
                    physics: _plans.length > 2
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _plans.length,
                    itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
                  ),
                ),
        ],
      ),
    );
  }

  /// Build a message when no plans are available
  Widget _buildEmptyPlansMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: AssetFlowColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          const Text(
            'No investment plans yet',
            style: TextStyle(
              fontSize: 16,
              color: AssetFlowColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addPlan,
            icon: const Icon(Icons.add),
            label: const Text('Add a Plan'),
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a card for a single plan
  Widget _buildPlanCard(Plan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: plan.isSelected
              ? AssetFlowColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan type and selected indicator
            PlanHeader(plan: plan),
            const SizedBox(height: 16),
            
            // Plan details
            PlanDetailsSection(plan: plan),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Select button
                TextButton.icon(
                  onPressed: plan.isSelected
                      ? null
                      : () => _selectPlan(plan),
                  icon: const Icon(Icons.check),
                  label: const Text('Select'),
                  style: TextButton.styleFrom(
                    foregroundColor: plan.isSelected
                        ? AssetFlowColors.textDisabled
                        : AssetFlowColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button - Made more prominent to fix visibility issue
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPlan(plan),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AssetFlowColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeletePlan(plan),
                  tooltip: 'Delete Plan',
                  color: AssetFlowColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle archive status of a project
  void _toggleArchiveStatus() {
    _logger.info('Toggle archive status for project: ${_project.id}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_project.isArchived ? 'Unarchive Investment' : 'Archive Investment'),
        content: Text(
          _project.isArchived
              ? 'Are you sure you want to unarchive "${_project.name}"?'
              : 'Are you sure you want to archive "${_project.name}"? It will be moved to the end of the list.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = true;
              });
              
              try {
                if (_project.isArchived) {
                  await _databaseService.unarchiveProject(_project.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Investment unarchived successfully')),
                    );
                  }
                } else {
                  await _databaseService.archiveProject(_project.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Investment archived successfully')),
                    );
                  }
                }
                
                // Reload the project data to show updated state
                await _loadProjectData();
              } catch (e) {
                _logger.severe('Error toggling archive status: $e');
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: _project.isArchived ? AssetFlowColors.primary : AssetFlowColors.secondary,
            ),
            child: Text(_project.isArchived ? 'Unarchive' : 'Archive'),
          ),
        ],
      ),
    );
  }

  /// Edit the project
/// Edit the project
void _editProject() {
  _logger.info('Edit project button pressed: ${widget.projectId}');
  
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => EditProjectScreen(
        project: _project,
      ),
    ),
  ).then((result) {
    // Reload project data if changes were made
    if (result == true) {
      _loadProjectData();
    }
  });
}

  /// Confirm project deletion
  void _confirmDeleteProject() {
    _logger.info('Delete project confirmation requested: ${widget.projectId}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text(
          'Are you sure you want to delete "${_project.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProject();
            },
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete the project
  Future<void> _deleteProject() async {
    _logger.info('Deleting project: ${widget.projectId}');
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deleteProject(widget.projectId);
      _logger.info('Project deleted successfully');
      
      if (mounted) {
        Navigator.of(context).pop(); // Return to list screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment deleted successfully')),
        );
      }
    } catch (e) {
      _logger.severe('Error deleting project: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting project: $e')),
        );
      }
    }
  }

  /// Add a new plan
  void _addPlan() {
    _logger.info('Add plan button pressed');
    
    final newPlan = Plan.create(
      name: 'New Plan',
      projectId: widget.projectId,
      annualInterest: 10.0,
      participationType: ParticipationType.limitedPartner,
      minimalAmount: 10000,
      lengthMonths: _project.projectLengthMonths,
      paymentDistribution: PaymentDistribution.quarterly,
      exitInterest: 5.0,
    );
    
    // Show dialog to add the plan
    showDialog(
        context: context,
        builder: (context) => PlanFormDialog(
          title: 'Add Investment Plan',
          plan: newPlan,
          project: _project,
          projectLength: _project.projectLengthMonths,
          onSave: (Plan plan) async {
          try {
            setState(() {
              _isLoading = true;
            });
            
            // Add the plan to the database
            final planId = await _databaseService.addPlanToProject(
              _project.id,
              plan,
            );
            
            _logger.info('Plan added successfully: $planId');
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan added successfully')),
              );
            }
          } catch (e) {
            _logger.severe('Error adding plan: $e');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding plan: $e')),
              );
            }
          }
        },
      ),
    );
  }

  /// Edit a plan
  void _editPlan(Plan plan) {
    _logger.info('Edit plan button pressed: ${plan.id}');
    
    // Show dialog to edit the plan
    showDialog(
      context: context,
      builder: (context) => PlanFormDialog(
        title: 'Edit Investment Plan',
        plan: plan,
        project: _project,
        projectLength: _project.projectLengthMonths,
        onSave: (updatedPlan) async {
          try {
            setState(() {
              _isLoading = true;
            });
            
            // Prepare data to update
            final data = {
              'minimalAmount': updatedPlan.minimalAmount,
              'annualInterest': updatedPlan.annualInterest,
              'exitInterest': updatedPlan.exitInterest,
              'lengthMonths': updatedPlan.lengthMonths,
              'participationType': updatedPlan.participationType.toString(),
              'paymentDistribution': updatedPlan.paymentDistribution.toString(),
              'isSelected': updatedPlan.isSelected,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            };
            
            // Update in Firestore
            await _databaseService.updatePlan(_project.id, plan.id, data);
            
            _logger.info('Plan updated successfully');
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan updated successfully')),
              );
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
        },
      ),
    );
  }

  /// Select a plan
  Future<void> _selectPlan(Plan plan) async {
    _logger.info('Select plan button pressed: ${plan.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      // Update all plans to be not selected
      for (final p in _plans) {
        if (p.isSelected) {
          await _databaseService.updatePlan(
            _project.id,
            p.id,
            {'isSelected': false},
          );
        }
      }

      // Set the selected plan
      await _databaseService.updatePlan(
        _project.id,
        plan.id,
        {'isSelected': true},
      );

      _logger.info('Plan selected successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan selected successfully')),
        );
      }
    } catch (e) {
      _logger.severe('Error selecting plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting plan: $e')),
        );
      }
    }
  }

  /// Confirm plan deletion
  void _confirmDeletePlan(Plan plan) {
    _logger.info('Delete plan confirmation requested: ${plan.id}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete this ${plan.participationType.displayName} plan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlan(plan);
            },
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete a plan
  Future<void> _deletePlan(Plan plan) async {
    _logger.info('Deleting plan: ${plan.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deletePlan(_project.id, plan.id);
      _logger.info('Plan deleted successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted successfully')),
        );
      }
    } catch (e) {
      _logger.severe('Error deleting plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting plan: $e')),
        );
      }
    }
  }
}