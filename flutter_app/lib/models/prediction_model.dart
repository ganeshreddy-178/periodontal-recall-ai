class PredictionModel {
  final int     id;
  final int     patientId;
  final String  finalSeverity;
  final String  finalRiskLevel;
  final double? finalConfidence;
  final String? cnnSeverity;
  final double? cnnConfidence;
  final double? clinicalRiskScore;
  final String? clinicalRiskLevel;
  final int     recallIntervalMin;
  final int     recallIntervalMax;
  final String? recommendations;
  final String  createdAt;

  const PredictionModel({
    required this.id,
    required this.patientId,
    required this.finalSeverity,
    required this.finalRiskLevel,
    required this.recallIntervalMin,
    required this.recallIntervalMax,
    required this.createdAt,
    this.finalConfidence,
    this.cnnSeverity,
    this.cnnConfidence,
    this.clinicalRiskScore,
    this.clinicalRiskLevel,
    this.recommendations,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> j) => PredictionModel(
    id:                j['id']                  as int,
    patientId:         j['patient_id']           as int,
    finalSeverity:     j['final_severity']       as String,
    finalRiskLevel:    j['final_risk_level']     as String,
    finalConfidence:   (j['final_confidence']    as num?)?.toDouble(),
    cnnSeverity:       j['cnn_severity']         as String?,
    cnnConfidence:     (j['cnn_confidence']      as num?)?.toDouble(),
    clinicalRiskScore: (j['clinical_risk_score'] as num?)?.toDouble(),
    clinicalRiskLevel: j['clinical_risk_level']  as String?,
    recallIntervalMin: j['recall_interval_min']  as int,
    recallIntervalMax: j['recall_interval_max']  as int,
    recommendations:   j['recommendations']      as String?,
    createdAt:         j['created_at']           as String,
  );
}
