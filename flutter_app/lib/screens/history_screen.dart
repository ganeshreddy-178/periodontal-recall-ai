import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PredictionProvider>();
    return Scaffold(
      key: const Key('history_screen'),
      appBar: AppBar(
        title: const Text('Prediction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PredictionProvider>().fetchHistory(),
          ),
        ],
      ),
      body: pp.loading
          ? const Center(child: CircularProgressIndicator())
          : pp.predictions.isEmpty
              ? const Center(child: Text('No predictions yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pp.predictions.length,
                  itemBuilder: (_, i) {
                    final pred = pp.predictions[i];
                    final sev  = pred.finalSeverity;
                    final risk = pred.finalRiskLevel;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.severityColor(sev).withOpacity(0.15),
                          child: Icon(Icons.biotech, color: AppTheme.severityColor(sev)),
                        ),
                        title: Row(children: [
                          Text(capitalize(sev),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.severityColor(sev))),
                          const SizedBox(width: 8),
                          _badge(capitalize(risk), AppTheme.riskColor(risk)),
                        ]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pred.finalConfidence != null)
                              Text('Confidence: ${pred.finalConfidence!.toStringAsFixed(1)}%'),
                            Text('Recall: ${pred.recallIntervalMin}–${pred.recallIntervalMax} months'),
                            Text(formatDate(pred.createdAt), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
