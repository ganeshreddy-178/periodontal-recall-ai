import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/patient_model.dart';
import '../providers/prediction_provider.dart';
import '../utils/helpers.dart';
import 'results_screen.dart';

class ImageUploadScreen extends StatefulWidget {
  final PatientModel patient;
  const ImageUploadScreen({super.key, required this.patient});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  XFile?       _xFile;       // works on all platforms
  Uint8List?   _webBytes;    // for web preview
  File?        _nativeFile;  // for native upload

  final _picker = ImagePicker();

  // Clinical sliders
  double _plaqueIndex       = 1.0;
  double _bleedingOnProbing = 20.0;
  double _pocketDepth       = 2.5;
  double _attachmentLoss    = 1.0;
  double _oralHygieneScore  = 7.0;

  Future<void> _pickImage(ImageSource src) async {
    final xf = await _picker.pickImage(source: src, imageQuality: 85);
    if (xf == null) return;

    if (kIsWeb) {
      final bytes = await xf.readAsBytes();
      setState(() { _xFile = xf; _webBytes = bytes; });
    } else {
      setState(() { _xFile = xf; _nativeFile = File(xf.path); });
    }
  }

  void _removeImage() {
    setState(() { _xFile = null; _webBytes = null; _nativeFile = null; });
  }

  Future<void> _runPrediction() async {
    final pp = context.read<PredictionProvider>();
    final ok = await pp.runPrediction(
      patientId:         widget.patient.id,
      plaqueIndex:       _plaqueIndex,
      bleedingOnProbing: _bleedingOnProbing,
      pocketDepth:       _pocketDepth,
      attachmentLoss:    _attachmentLoss,
      oralHygieneScore:  _oralHygieneScore,
      imageFile:         kIsWeb ? null : _nativeFile,
      webImageBytes:     kIsWeb ? _webBytes : null,
      webImageName:      kIsWeb ? (_xFile?.name) : null,
    );
    if (!mounted) return;
    if (ok && pp.latest != null) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultsScreen(
              prediction: pp.latest!, patient: widget.patient)));
    } else {
      showSnack(context, pp.error ?? 'Prediction failed.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<PredictionProvider>().loading;

    return Scaffold(
      appBar: AppBar(title: Text('Scan: ${widget.patient.fullName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Image section ----
            const Text('Dental Image (optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  border: Border.all(color: const Color(0xFFBDBDBD), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildImagePreview(),
              ),
            ),
            if (_xFile != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove Image',
                    style: TextStyle(color: Colors.red)),
              ),
            ],

            const SizedBox(height: 24),
            // ---- Clinical parameters ----
            const Text('Clinical Parameters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 12),

            _sliderField('Plaque Index',         _plaqueIndex,       0, 3,   1,
                (v) => setState(() => _plaqueIndex = v),       suffix: '/ 3.0'),
            _sliderField('Bleeding on Probing',  _bleedingOnProbing, 0, 100, 1,
                (v) => setState(() => _bleedingOnProbing = v), suffix: '%'),
            _sliderField('Pocket Depth (mm)',    _pocketDepth,       0, 10,  0.5,
                (v) => setState(() => _pocketDepth = v),       suffix: ' mm'),
            _sliderField('Attachment Loss (mm)', _attachmentLoss,    0, 12,  0.5,
                (v) => setState(() => _attachmentLoss = v),    suffix: ' mm'),
            _sliderField('Oral Hygiene Score',   _oralHygieneScore,  0, 10,  0.5,
                (v) => setState(() => _oralHygieneScore = v),  suffix: '/ 10'),

            const SizedBox(height: 32),
            loading
                ? const Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Running AI analysis…',
                        style: TextStyle(color: Colors.grey)),
                  ])
                : ElevatedButton.icon(
                    onPressed: _runPrediction,
                    icon: const Icon(Icons.psychology),
                    label: const Text('Analyse & Predict'),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- Image preview: handles web bytes vs native File ----
  Widget _buildImagePreview() {
    if (_xFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Tap to add dental image',
              style: TextStyle(color: Colors.grey)),
          Text('JPG, JPEG, PNG supported',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    if (kIsWeb && _webBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(_webBytes!, fit: BoxFit.cover,
            width: double.infinity, height: 200),
      );
    }

    if (!kIsWeb && _nativeFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(_nativeFile!, fit: BoxFit.cover,
            width: double.infinity, height: 200),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _sliderField(String label, double value, double min, double max,
      double divisions, ValueChanged<double> onChanged, {String suffix = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${value.toStringAsFixed(1)}$suffix',
                style: const TextStyle(
                    color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value, min: min, max: max,
          divisions: ((max - min) / divisions).round(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Select Image Source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery / File'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
