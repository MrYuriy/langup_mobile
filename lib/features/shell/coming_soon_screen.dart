import 'package:flutter/material.dart';

/// Placeholder for tabs delivered in later phases (Practice, Review, Dashboard).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.phase});

  final String title;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction,
                  size: 56, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              Text('$title — coming in $phase',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
