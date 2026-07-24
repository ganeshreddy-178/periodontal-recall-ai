import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../models/patient_model.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class ResultsScreen extends StatelessWidget {
  final PredictionModel prediction;
  final PatientModel    patient;

  const ResultsScreen({
    super.key,
    required this.prediction,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final sev   = prediction.finalSeverity;
    final risk  = prediction.finalRiskLevel;
    final conf  = prediction.finalConfidence ?? 0.0;
    final grad  = AppTheme.severityGradient(sev);
    final color = AppTheme.severityColor(sev);

    return Scaffold(
      key: const Key('results_screen'),
      backgroundColor: AppTheme.surface,
        slivers: [
          // ── Hero header ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Analysis Results',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: grad),
                child: Stack(children: [
                  Positioned(top: -30, right: -30,
                      child: _circle(160, Colors.white.withOpacity(0.08))),
                  Positioned(bottom: -20, left: -40,
                      child: _circle(180, Colors.white.withOpacity(0.05))),
                  Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(_sevIcon(sev),
                            size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text('${capitalize(sev)} Periodontitis',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      _confBadge(conf),
                    ],
                  )),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // ── Risk level ──
                _RiskBanner(risk: risk),
                const SizedBox(height: 16),

                // ── AI breakdown ──
                _InfoCard(
                  title: 'AI Analysis Breakdown',
                  icon: Icons.psychology_rounded,
                  children: [
                    if (prediction.cnnSeverity != null)
                      _Row('CNN Image Result',
                          '${capitalize(prediction.cnnSeverity!)}  '
                          '(${prediction.cnnConfidence?.toStringAsFixed(1) ?? '—'}%)'),
                    if (prediction.clinicalRiskScore != null)
                      _Row('Clinical Risk Score',
                          '${prediction.clinicalRiskScore!.toStringAsFixed(1)} / 100'),
                    if (prediction.clinicalRiskLevel != null)
                      _Row('Clinical Risk Level',
                          capitalize(prediction.clinicalRiskLevel!)),
                    _Row('Final Severity',  capitalize(sev)),
                    _Row('Final Risk',      capitalize(risk)),
                    _Row('Confidence',      '${conf.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Patient ──
                _InfoCard(
                  title: 'Patient',
                  icon: Icons.person_rounded,
                  children: [
                    _Row('Name',   patient.fullName),
                    _Row('Age',    '${patient.age} years'),
                    _Row('Gender', capitalize(patient.gender)),
                    _Row('Date',   formatDate(prediction.createdAt)),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Recall ──
                _RecallCard(prediction: prediction),
                const SizedBox(height: 14),

                // ── Recommendations ──
                if (prediction.recommendations != null)
                  _RecommendationsCard(text: prediction.recommendations!),

                const SizedBox(height: 24),
                // Back button
                GestureDetector(
                  onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradientPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 14, offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Back to Dashboard',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _confBadge(double conf) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.4)),
    ),
    child: Text('${conf.toStringAsFixed(1)}% confidence',
        style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w600, fontSize: 13)),
  );

  IconData _sevIcon(String s) {
    switch (s) {
      case 'healthy':  return Icons.sentiment_very_satisfied_rounded;
      case 'mild':     return Icons.sentiment_satisfied_rounded;
      case 'moderate': return Icons.sentiment_dissatisfied_rounded;
      case 'severe':   return Icons.sentiment_very_dissatisfied_rounded;
      default:         return Icons.health_and_safety_rounded;
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────

class _RiskBanner extends StatelessWidget {
  final String risk;
  const _RiskBanner({required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.riskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(risk == 'high'
            ? Icons.warning_rounded
            : risk == 'moderate'
                ? Icons.info_rounded
                : Icons.check_circle_rounded,
            color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${capitalize(risk)} Risk Level',
              style: TextStyle(color: color,
                  fontWeight: FontWeight.w800, fontSize: 16)),
          Text(risk == 'high'
              ? 'Immediate attention required'
              : risk == 'moderate'
                  ? 'Regular monitoring recommended'
                  : 'Good periodontal health',
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String         title;
  final IconData       icon;
  final List<Widget>   children;
  const _InfoCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, 5)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15,
              color: AppTheme.textDark)),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 20, color: Color(0xFFEEF0FA)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: children),
      ),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(
            color: AppTheme.textMid, fontSize: 13)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark, fontSize: 13)),
      ],
    ),
  );
}

class _RecallCard extends StatelessWidget {
  final PredictionModel prediction;
  const _RecallCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final next = DateTime.now().add(
        Duration(days: prediction.recallIntervalMin * 30));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calendar_month_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Text('Recall Schedule',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.schedule_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Every ${prediction.recallIntervalMin}–${prediction.recallIntervalMax} months',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.event_available_rounded,
              color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text('Next visit: ${formatDate(next.toIso8601String())}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final String text;
  const _RecommendationsCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, 5)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tips_and_updates_rounded,
              size: 16, color: AppTheme.accent),
        ),
        const SizedBox(width: 10),
        const Text('Recommendations',
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 15, color: AppTheme.textDark)),
      ]),
      const SizedBox(height: 12),
      Text(text,
          style: const TextStyle(
              height: 1.7, fontSize: 13, color: AppTheme.textMid)),
    ]),
  );
}
