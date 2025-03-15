import 'package:flutter/material.dart';
import '../utils/theme_colors.dart';

/// A reusable dashboard tile widget
class DashboardTile extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  
  const DashboardTile({
    Key? key,
    required this.title,
    required this.child,
    this.height,
    this.trailingWidget,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(bottom: 16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Container(
            height: height,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AssetFlowColors.textPrimary,
                      ),
                    ),
                    if (trailingWidget != null) trailingWidget!,
                  ],
                ),
                const SizedBox(height: 16.0),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}