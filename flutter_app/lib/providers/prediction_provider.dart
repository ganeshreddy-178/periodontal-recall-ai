import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';

class PredictionProvider extends ChangeNotifier {
  List<PredictionModel> _predictions = [];
  PredictionModel?      _latest;
  bool                  _loading     = false;
  String?               _error;

  List<PredictionModel> get predictions => _predictions;
  PredictionModel?      get latest      => _latest;
  bool                  get loading     => _loading;
  String?               get error       => _error;

  Future<bool> runPrediction({
    required int     patientId,
    required double  plaqueIndex,
    required double  bleedingOnProbing,
    required double  pocketDepth,
    required double  attachmentLoss,
    required double  oralHygieneScore,
    File?            imageFile,
    Uint8List?       webImageBytes,
    String?          webImageName,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.predict(
        patientId:         patientId,
        plaqueIndex:       plaqueIndex,
        bleedingOnProbing: bleedingOnProbing,
        pocketDepth:       pocketDepth,
        attachmentLoss:    attachmentLoss,
        oralHygieneScore:  oralHygieneScore,
        imageFile:         imageFile,
        webImageBytes:     webImageBytes,
        webImageName:      webImageName,
      );
      if (res['success'] == true) {
        _latest = PredictionModel.fromJson(
          (res['data'] as Map<String, dynamic>)['prediction']
              as Map<String, dynamic>,
        );
        _loading = false; notifyListeners();
        return true;
      }
      _error = res['message'] as String? ?? 'Prediction failed.';
    } catch (e) {
      _error = 'Network error during prediction.';
    }
    _loading = false; notifyListeners();
    return false;
  }

  Future<void> fetchHistory() async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.getPredictions();
      if (res['success'] == true) {
        _predictions = (res['data'] as List)
            .map((e) => PredictionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    _loading = false; notifyListeners();
  }

  void clearLatest() { _latest = null; notifyListeners(); }
}
