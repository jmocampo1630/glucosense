import 'package:flutter/material.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const double cardSpacing = 8;
  static const double cardPadding = 14;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card using the same style as SummaryCard
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: cardPadding, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.blue.shade100,
                        width: 3,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.person, size: 32, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.cake, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Age: 45',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.wc, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Sex: Female',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Last Record: 2024-06-09',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: cardSpacing + 6),
          // Summary Cards Row
          Row(
            children: [
              SummaryCard(
                title: 'Latest',
                value: '120',
                unit: 'mg/dL',
                color: Colors.blue.shade50,
                icon: Icons.bolt,
                iconColor: Colors.blue,
              ),
              const SizedBox(width: cardSpacing),
              SummaryCard(
                title: 'Avg (7d)',
                value: '110',
                unit: 'mg/dL',
                color: Colors.green.shade50,
                icon: Icons.show_chart,
                iconColor: Colors.green,
              ),
              const SizedBox(width: cardSpacing),
              SummaryCard(
                title: 'Records',
                value: '42',
                unit: '',
                color: Colors.grey.shade100,
                icon: Icons.list_alt,
                iconColor: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: cardSpacing),
          // High & Low Cards Row
          Row(
            children: [
              SummaryCard(
                title: 'High',
                value: '180',
                unit: 'mg/dL',
                color: Colors.red.shade50,
                icon: Icons.arrow_upward,
                iconColor: Colors.red,
              ),
              const SizedBox(width: cardSpacing),
              SummaryCard(
                title: 'Low',
                value: '70',
                unit: 'mg/dL',
                color: Colors.orange.shade50,
                icon: Icons.arrow_downward,
                iconColor: Colors.orange,
              ),
            ],
          ),
          // Add more cards/widgets below as needed
        ],
      ),
    );
  }
}
