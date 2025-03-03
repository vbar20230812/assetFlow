import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'investment_models.dart';

class DistributionDetailView extends StatefulWidget {
  final Project project;
  final Function(String, bool) onDistributionStatusChanged;
  
  const DistributionDetailView({
    super.key,
    required this.project,
    required this.onDistributionStatusChanged,
  });

  @override
  DistributionDetailViewState createState() => DistributionDetailViewState();
}

class DistributionDetailViewState extends State<DistributionDetailView> {
  String _filterStatus = 'all';
  
  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final currencyFormat = NumberFormat.currency(
      symbol: project.currency,
      decimalDigits: 0,
    );
    
    // Filter distributions based on selected filter
    List<Distribution> filteredDistributions = project.distributions;
    if (_filterStatus == 'paid') {
      filteredDistributions = project.distributions.where((dist) => dist.done).toList();
    } else if (_filterStatus == 'pending') {
      filteredDistributions = project.distributions.where((dist) => !dist.done).toList();
    } else if (_filterStatus == 'upcoming') {
      filteredDistributions = project.distributions.where((dist) => dist.isUpcoming(30)).toList();
    } else if (_filterStatus == 'overdue') {
      filteredDistributions = project.distributions.where((dist) => dist.isOverdue()).toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${project.projectName} Distributions'),
      ),
      body: Column(
        children: [
          // Summary section
          _buildSummarySection(project, currencyFormat),
          
          // Filter options
          _buildFilterOptions(),
          
          // Distributions table
          Expanded(
            child: filteredDistributions.isEmpty
                ? Center(child: Text('No distributions match the selected filter'))
                : _buildDistributionsTable(project, filteredDistributions, currencyFormat),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummarySection(Project project, NumberFormat currencyFormat) {
    final completedCount = project.getCompletedDistributionsCount();
    final totalCount = project.distributions.length;
    final paidAmount = project.getCompletedDistributionsTotal();
    final remainingAmount = project.getRemainingDistributionsTotal();
    
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  'Progress',
                  '$completedCount of $totalCount',
                  '${(completedCount * 100 / totalCount).toStringAsFixed(1)}%',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: _buildSummaryStat(
                  'Paid Amount',
                  currencyFormat.format(paidAmount),
                  '${(paidAmount * 100 / (paidAmount + remainingAmount)).toStringAsFixed(1)}%',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: _buildSummaryStat(
                  'Remaining',
                  currencyFormat.format(remainingAmount),
                  '',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: completedCount / totalCount,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryStat(String label, String value, String subvalue) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subvalue.isNotEmpty)
          Text(
            subvalue,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
  
  Widget _buildFilterOptions() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            SizedBox(width: 8),
            _buildFilterChip('Paid', 'paid'),
            SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending'),
            SizedBox(width: 8),
            _buildFilterChip('Upcoming', 'upcoming'),
            SizedBox(width: 8),
            _buildFilterChip('Overdue', 'overdue'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: Color.fromRGBO(
        Theme.of(context).primaryColor.r.toInt(),
        Theme.of(context).primaryColor.g.toInt(),
        Theme.of(context).primaryColor.b.toInt(),
        0.2
      ),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
  
  Widget _buildDistributionsTable(
    Project project, 
    List<Distribution> distributions, 
    NumberFormat currencyFormat
  ) {
    return ListView.builder(
      itemCount: distributions.length,
      itemBuilder: (context, index) {
        final dist = distributions[index];
        bool isUpcoming = dist.isUpcoming(30);
        bool isOverdue = dist.isOverdue();
        
        // Background color based on status
        Color? backgroundColor;
        if (dist.done) {
          backgroundColor = Colors.green.withAlpha(26); // 0.1 opacity = roughly 26 alpha (10% of 255)
        } else if (isOverdue) {
          backgroundColor = Colors.red.withAlpha(26);
        } else if (isUpcoming) {
          backgroundColor = Colors.amber.withAlpha(26);
        }
        return Container(
          color: backgroundColor,
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    dist.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    currencyFormat.format(dist.plannedAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dist.done ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(dist.date),
                ),
                Expanded(
                  flex: 3,
                  child: Text(_formatDistributionType(dist.type)),
                ),
              ],
            ),
            trailing: Checkbox(
              value: dist.done,
              activeColor: Colors.green,
              onChanged: (bool? value) {
                if (value != null) {
                  widget.onDistributionStatusChanged(dist.date, value);
                }
              },
            ),
          ),
        );
      },
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