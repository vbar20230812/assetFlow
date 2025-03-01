import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'add_investment_screen.dart';
import 'investment_service.dart';
import 'investment_models.dart';
import 'widgets/asset_flow_loader.dart';

class InvestmentsListScreen extends StatefulWidget {
  const InvestmentsListScreen({super.key});

  @override
  InvestmentsListScreenState createState() => InvestmentsListScreenState();
}

class InvestmentsListScreenState extends State<InvestmentsListScreen> {
  static final Logger _logger = Logger('InvestmentsListScreen');
  final InvestmentService _investmentService = InvestmentService();
  bool _isLoading = true;
  UserInvestments? _userInvestments;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final investmentsData = await _investmentService.getInvestments();
      setState(() {
        _userInvestments = UserInvestments.fromMap(investmentsData);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading investments: $e');
      setState(() {
        _errorMessage = 'Failed to load investments: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Investments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvestments,
          ),
        ],
      ),
      body: _buildBody(),
      // Here is the correct placement of the FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddInvestmentScreen()),
            );
            
            if (result == true) {
              _loadInvestments();
            }
          } catch (e) {
            _logger.severe('Error navigating to AddInvestmentScreen: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open Add Investment screen: ${e.toString()}')),
            );
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Investment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AssetFlowLoader(
              size: 80,
              primaryColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
            const SizedBox(height: 16),
            const Text('Loading your investments...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage!),
            ),
            ElevatedButton(
              onPressed: _loadInvestments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_userInvestments == null || _userInvestments!.projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance,
                  size: 80,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ready to grow your wealth?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "We're curious about your investment plans! Add your first investment to start tracking your portfolio growth.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddInvestmentScreen()),
                    );
                    
                    if (result == true) {
                      _loadInvestments();
                    }
                  } catch (e) {
                    _logger.severe('Error navigating to AddInvestmentScreen: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to open Add Investment screen: ${e.toString()}')),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Investment'),
              ),
            ],
          ),
        ),
      );
    }

    // If we have investments to display, we would show them here
    // This is a simplified version - you can expand this with your actual UI for showing investments
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userInvestments!.projects.length,
      itemBuilder: (context, index) {
        final project = _userInvestments!.projects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(project.projectName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${project.currency} ${project.investmentAmount}'),
            trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor),
            onTap: () {
              // Navigate to project details
            },
          ),
        );
      },
    );
  }
}