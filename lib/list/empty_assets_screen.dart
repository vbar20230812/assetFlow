import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../utils/theme_colors.dart';
import '../new/add_investment_screen.dart';

/// Screen that displays when the user has no assets/investments
class EmptyAssetsScreen extends StatelessWidget {
  static final Logger _logger = Logger('EmptyAssetsScreen');

  const EmptyAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 120,
              color: AssetFlowColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 24),
            
            // Title text
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
            
            // Description text
            const Text(
              'Track your investments, manage distribution plans, and monitor returns all in one place.',
              style: TextStyle(
                fontSize: 16,
                color: AssetFlowColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Add first investment button
            SizedBox(
              width: 240,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _logger.info('Add first investment button pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddInvestmentScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add First Investment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AssetFlowColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}