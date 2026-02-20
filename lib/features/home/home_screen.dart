import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav.dart';
import 'ootd_menu.dart';
import '../../asset/style_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('OOTD'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: const OotdMenu(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Outfit Of Today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: List.generate(
                      4,
                      (_) => Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Other styles you might like.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/wardrobe');
                        },
                        child: const Text(
                          'Suggest new →',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                StyleButton(
                  label: 'Style Labs',
                  icon: Icons.checkroom_outlined,
                  color: Color(0xFF4A7C8C),
                  onPressed: () => Navigator.pushNamed(context, '/style-lab'),
                ),

                const Spacer(),
                StyleButton(
                  label: 'Styles Planner',
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF2D2926),
                  onPressed: () => Navigator.pushNamed(context, '/planner'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Trending Outfits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: List.generate(
                2,
                (_) => Expanded(
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Lorem Ipsum'), Text('Lorem Ipsum')],
            ),
          ],
        ),
      ),

      bottomNavigationBar: const AppBottomNav(current: 0),
    );
  }
}
