import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../widgets/svg_icon.dart';

class SvgGallerySheet extends StatelessWidget {
  const SvgGallerySheet({super.key});

  static const List<(String, String)> _icons = [
    ('assets/svg/clock.svg', 'Clock'),
    ('assets/svg/radio.svg', 'Radio'),
    ('assets/svg/water_drop.svg', 'Water'),
    ('assets/svg/food_can.svg', 'Food'),
    ('assets/svg/map_pin.svg', 'Map'),
    ('assets/svg/shelter.svg', 'Shelter'),
    ('assets/svg/tools.svg', 'Tools'),
    ('assets/svg/leaf.svg', 'Leaf'),
    ('assets/svg/antenna.svg', 'Antenna'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.palette, color: GameColors.gold),
                    const SizedBox(width: 12),
                    Text('SVG Style Preview', style: GameTypography.heading2),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _icons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final (path, label) = _icons[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: GameColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GameColors.surfaceLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GameSvgIcon(
                            assetPath: path,
                            size: 36,
                            color: GameColors.textPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: GameTypography.caption,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
