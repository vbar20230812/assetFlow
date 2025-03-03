import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'investment_models.dart';

class InvestmentDetailCard extends StatefulWidget {
  final Project project;
  
  const InvestmentDetailCard({
    super.key,
    required this.project,
  });
  
  @override
  InvestmentDetailCardState createState() => InvestmentDetailCardState();
}

class InvestmentDetailCardState extends State<InvestmentDetailCard> {
  bool _showDistributions = false;
  
  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final selectedPlan = project.getSelectedPlan();
    final currencyFormat = NumberFormat.currency(
      symbol: project.currency,
      decimalDigits: 0,
    );
    //final percentFormat = NumberFormat.decimalPercentPattern(
    //  decimalDigits: 1,
    //);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.projectName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        project.companyName,
                        style: TextStyle(
                         color: Colors.white.withAlpha(204), // 0.8 opacity = 204 alpha (80% of 255) 
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(204), // 0.8 opacity = 204 alpha (80% of 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedPlan?.getInvestorTypeDescription() ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress indicator
          LinearProgressIndicator(
            value: project.getProgressPercentage() / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Investment Progress: ${project.getProgressPercentage().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Investment Summary
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investment Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  'Investment Amount', 
                  currencyFormat.format(project.investmentAmount)
                ),
                _buildDetailRow(
                  'Total Investment', 
                  currencyFormat.format(project.getTotalInvestment())
                ),
                _buildDetailRow(
                  'Plan', 
                  selectedPlan?.planName ?? 'Unknown'
                ),
                _buildDetailRow(
                  'Interest Rate', 
                  '${selectedPlan?.interest ?? 0}%'
                ),
                _buildDetailRow(
                  'Payment Period', 
                  selectedPlan?.plannedDistributions.getPaymentPeriodDescription() ?? 'Unknown'
                ),
                _buildDetailRow(
                  'Investment Term', 
                  '${selectedPlan?.periodMonths ?? 0} months'
                ),
                _buildDetailRow(
                  'Expected Returns', 
                  currencyFormat.format(project.calculateTotalInterest())
                ),
                _buildDetailRow(
                  'Total Funds Return', 
                  currencyFormat.format(project.calculateTotalFunds())
                ),
                //_buildDetailRow(
                //  'Actual Return Rate', 
                //  percentFormat.format(project.calculateActualReturn() / 100)
                //),
              ],
            ),
          ),
          
          // Dates Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Dates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  'Contract Date', 
                  project.dateOfContractSign
                ),
                _buildDetailRow(
                  'First Payment', 
                  project.dateOfFirstPayment
                ),
                _buildDetailRow(
                  'Exit Date', 
                  project.dateOfExit
                ),
                _buildDetailRow(
                  'Next Distribution', 
                  project.getNextDistributionDate()
                ),
              ],
            ),
          ),
          
          // Distribution Progress
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribution Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  'Completed', 
                  '${project.getCompletedDistributionsCount()} of ${project.distributions.length}'
                ),
                _buildDetailRow(
                  'Paid So Far', 
                  currencyFormat.format(project.getCompletedDistributionsTotal())
                ),
                _buildDetailRow(
                  'Remaining', 
                  currencyFormat.format(project.getRemainingDistributionsTotal())
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distribution Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showDistributions = !_showDistributions;
                        });
                      },
                      child: Text(_showDistributions ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                if (_showDistributions) _buildDistributionsTable(project, currencyFormat),
              ],
            ),
          ),
          
          // Notes Section if not empty
          if (project.notes.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(project.notes),
                ],
              ),
            ),
          
          // Action buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                  onPressed: () {
                    // Edit functionality would be implemented later
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit functionality coming soon')),
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    // Delete functionality would be handled by the parent widget
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Deletion'),
                        content: Text('Are you sure you want to delete this investment?\nThis action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Call delete function from parent
                            },
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
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
  
  Widget _buildDistributionsTable(Project project, NumberFormat currencyFormat) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Status')),
            ],
            rows: project.distributions.map((dist) {
              // Determine if this distribution is upcoming or overdue
              bool isUpcoming = dist.isUpcoming(30); // Next 30 days
              bool isOverdue = dist.isOverdue();
              
              // Define cell styles based on status
              Color? rowColor;
                if (dist.done) {
                  rowColor = Colors.green.withAlpha(26); // 0.1 opacity = 26 alpha (10% of 255)
                } else if (isOverdue) {
                  rowColor = Colors.red.withAlpha(26);
                } else if (isUpcoming) {
                  rowColor = Colors.amber.withAlpha(26);
                }
              return DataRow(
                color: rowColor != null ? WidgetStateProperty.all(rowColor) : null,
                cells: [
                  DataCell(Text(dist.date)),
                  DataCell(Text(dist.name)),
                  DataCell(Text(currencyFormat.format(dist.plannedAmount))),
                  DataCell(Text(_formatDistributionType(dist.type))),
                  DataCell(_buildStatusCell(dist, isUpcoming, isOverdue)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCell(Distribution dist, bool isUpcoming, bool isOverdue) {
    Widget icon;
    String text;
    Color color;
    
    if (dist.done) {
      icon = Icon(Icons.check_circle, color: Colors.green, size: 16);
      text = 'Paid';
      color = Colors.green;
    } else if (isOverdue) {
      icon = Icon(Icons.warning, color: Colors.red, size: 16);
      text = 'Overdue';
      color = Colors.red;
    } else if (isUpcoming) {
      icon = Icon(Icons.schedule, color: Colors.amber, size: 16);
      text = 'Soon';
      color = Colors.amber;
    } else {
      icon = Icon(Icons.schedule, color: Colors.grey, size: 16);
      text = 'Pending';
      color = Colors.grey;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
  
  String _formatDistributionType(String type) {
    switch (type.toLowerCase()) {
      case 'quarter':
        return 'Quarterly';
      case 'half':
        return 'Semi-annual';
      case 'yearly':
        return 'Annual';
      case 'exit':
        return 'Exit';
      default:
        return type;
    }
  }
}