import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../utils/theme_colors.dart';
import '../new/add_investment_screen.dart';

/// Screen displayed when the user has no investments yet
class EmptyAssetsScreen extends StatelessWidget {
  static final Logger _logger = Logger('EmptyAssetsScreen');

  const EmptyAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.info('EmptyAssetsScreen built');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AssetFlowColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: AssetFlowColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'No Investments Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AssetFlowColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            const Text(
              'Start tracking your investments by adding your first project.',
              style: TextStyle(
                fontSize: 16,
                color: AssetFlowColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Add investment button
            ElevatedButton.icon(
              onPressed: () {
                _logger.info('Add first investment button pressed');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddInvestmentScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Investment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AssetFlowColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(240, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}