import 'package:flutter/material.dart';
import 'asset_flow_loader.dart';

/// A loading overlay widget that shows a loader over the content
class AssetFlowLoadingWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;
  
  const AssetFlowLoadingWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,
        
        // Show loader overlay when loading
        if (isLoading)
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.5),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssetFlowLoader(
                    size: 80,
                    primaryColor: Theme.of(context).primaryColor,
                    duration: const Duration(seconds: 3),
                  ),
                  if (loadingText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        loadingText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}