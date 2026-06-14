import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'patient_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash   = context.watch<DashboardProvider>();
    final auth   = context.watch<AuthProvider>();
    final data   = dash.data;
    final trends = dash.trends;
    final risk   = (data['risk_distribution'] as Map?)?.cast<String, int>()
        ?? {'low': 0, 'moderate': 0, 'high': 0};
    final sev = (data['severity_distribution'] as Map?)?.cast<String, int>()
        ?? {'healthy': 0, 'mild': 0, 'moderate': 0, 'severe': 0};

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: dash.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<DashboardProvider>().load(),
              child: CustomScrollView(
                slivers: [
                  // ── Gradient AppBar ──
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppTheme.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                            gradient: AppTheme.gradientPrimary),
                        child: Stack(children: [
                          Positioned(top: -30, right: -30,
                              child: _circle(160,
                                  Colors.white.withOpacity(0.06))),
                          Positioned(bottom: -20, left: -20,
                              child: _circle(120,
                                  Colors.white.withOpacity(0.04))),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Hello, ${auth.user?.fullName.split(' ').first ?? ''}! 👋',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text('Here\'s your clinic overview',
                                    style: TextStyle(fontSize: 13,
                                        color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            context.read<DashboardProvider>().load(),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stat cards row ──
                          Row(children: [
                            _StatCard(
                              label:    'Total Patients',
                              value:    '${data['total_patients'] ?? 0}',
                              icon:     Icons.people_alt_rounded,
                              gradient: AppTheme.gradientPrimary,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label:    'Total Scans',
                              value:    '${data['total_predictions'] ?? 0}',
                              icon:     Icons.biotech_rounded,
                              gradient: AppTheme.gradientAccent,
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _StatCard(
                              label:    'Low Risk',
                              value:    '${risk['low'] ?? 0}',
                              icon:     Icons.check_circle_rounded,
                              gradient: AppTheme.gradientSuccess,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label:    'High Risk',
                              value:    '${risk['high'] ?? 0}',
                              icon:     Icons.warning_rounded,
                              gradient: AppTheme.gradientDanger,
                            ),
                          ]),

                          const SizedBox(height: 24),
                          // ── Risk Distribution ──
                          _SectionHeader(title: 'Risk Distribution',
                              icon: Icons.pie_chart_rounded),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: SizedBox(
                              height: 200,
                              child: _buildPie(risk),
                            ),
                          ),

                          const SizedBox(height: 20),
                          // ── Severity Distribution ──
                          _SectionHeader(title: 'Severity Breakdown',
                              icon: Icons.bar_chart_rounded),
                          const SizedBox(height: 12),
                          _GlassCard(child: _SeverityBars(sev: sev)),

                          const SizedBox(height: 20),
                          // ── Monthly Trend ──
                          _SectionHeader(title: 'Monthly Predictions',
                              icon: Icons.trending_up_rounded),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: SizedBox(
                              height: 180,
                              child: _buildTrend(trends),
                            ),
                          ),

                          const SizedBox(height: 20),
                          // ── Recent Predictions ──
                          _SectionHeader(title: 'Recent Predictions',
                              icon: Icons.history_rounded),
                          const SizedBox(height: 12),
                          ...((data['recent_predictions'] as List?) ?? [])
                              .map((e) => _RecentCard(
                                  item: e as Map<String, dynamic>)),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientPrimary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'dashboard_fab',
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PatientFormScreen())),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('New Patient',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildPie(Map<String, int> risk) {
    final total =
        (risk['low']! + risk['moderate']! + risk['high']!).toDouble();
    if (total == 0) {
      return const Center(
          child: Text('No data yet', style: TextStyle(color: Colors.grey)));
    }
    return PieChart(PieChartData(
      sectionsSpace: 3,
      centerSpaceRadius: 48,
      sections: [
        PieChartSectionData(
            value: risk['low']!.toDouble(),
            color: AppTheme.riskLow, radius: 55,
            title: '${risk['low']}',
            titleStyle: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13)),
        PieChartSectionData(
            value: risk['moderate']!.toDouble(),
            color: AppTheme.riskModerate, radius: 55,
            title: '${risk['moderate']}',
            titleStyle: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13)),
        PieChartSectionData(
            value: risk['high']!.toDouble(),
            color: AppTheme.riskHigh, radius: 55,
            title: '${risk['high']}',
            titleStyle: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13)),
      ],
      pieTouchData: PieTouchData(enabled: true),
    ));
  }

  Widget _buildTrend(List<dynamic> trends) {
    if (trends.isEmpty) {
      return const Center(
          child: Text('No trend data', style: TextStyle(color: Colors.grey)));
    }
    final spots = trends.asMap().entries.map((e) => FlSpot(
      e.key.toDouble(),
      ((e.value as Map)['count'] as int).toDouble(),
    )).toList();
    return LineChart(LineChartData(
      gridData:    FlGridData(show: false),
      borderData:  FlBorderData(show: false),
      titlesData:  FlTitlesData(
        topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles:AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:  AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textLight)))),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          color: AppTheme.accent,
          barWidth: 3,
          dotData: FlDotData(show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4, color: AppTheme.accent,
                  strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.accent.withOpacity(0.25),
                AppTheme.accent.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.35),
            blurRadius: 14, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.8), fontSize: 11)),
        ]),
      ]),
    ),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withOpacity(0.07),
          blurRadius: 20, offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionHeader extends StatelessWidget {
  final String  title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
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
        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
  ]);
}

class _SeverityBars extends StatelessWidget {
  final Map<String, int> sev;
  const _SeverityBars({required this.sev});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Healthy',  sev['healthy']  ?? 0, AppTheme.riskLow),
      ('Mild',     sev['mild']     ?? 0, const Color(0xFF64DD17)),
      ('Moderate', sev['moderate'] ?? 0, AppTheme.riskModerate),
      ('Severe',   sev['severe']   ?? 0, AppTheme.riskHigh),
    ];
    final maxVal = items.map((e) => e.$2).reduce((a, b) => a > b ? a : b);

    return Column(
      children: items.map((item) {
        final pct = maxVal == 0 ? 0.0 : item.$2 / maxVal;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(width: 68,
                child: Text(item.$1,
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.textMid))),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 12,
                backgroundColor: item.$3.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(item.$3),
              ),
            )),
            const SizedBox(width: 8),
            Text('${item.$2}',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: item.$3)),
          ]),
        );
      }).toList(),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _RecentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final sev  = (item['final_severity']  as String?) ?? 'healthy';
    final risk = (item['final_risk_level'] as String?) ?? 'low';
    final conf = (item['final_confidence'] as num?)?.toDouble() ?? 0;
    final color = AppTheme.severityColor(sev);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.biotech_rounded, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(capitalize(sev),
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: color, fontSize: 14)),
            Text(formatDate(item['created_at'] as String?),
                style: const TextStyle(fontSize: 11,
                    color: AppTheme.textLight)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _badge(capitalize(risk), AppTheme.riskColor(risk)),
          const SizedBox(height: 4),
          Text('${conf.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11,
                  color: AppTheme.textMid, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w700)),
  );
}
