import 'package:flutter/material.dart';
import '../extras/ui_extras.dart';

/// Esqueleto que se muestra mientras cargan las citas.
class CitasSkeletonList extends StatelessWidget {
  const CitasSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: 3,
      itemBuilder: (context, _) => const Card(
        margin: EdgeInsets.only(bottom: 12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 16)),
                  SizedBox(width: 16),
                  SkeletonBox(width: 72, height: 22, radius: 20),
                ],
              ),
              SizedBox(height: 12),
              SkeletonBox(height: 12),
              SizedBox(height: 6),
              SkeletonBox(width: 180, height: 12),
              SizedBox(height: 16),
              SkeletonBox(width: 150, height: 12),
              SizedBox(height: 16),
              SkeletonBox(height: 5, radius: 3),
            ],
          ),
        ),
      ),
    );
  }
}
