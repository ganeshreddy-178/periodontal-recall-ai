import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(String? isoDate) {
  if (isoDate == null) return '—';
  try {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy').format(dt);
  } catch (_) {
    return isoDate;
  }
}

String capitalize(String? s) {
  if (s == null || s.isEmpty) return '';
  return s[0].toUpperCase() + s.substring(1);
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Colors.red[700] : Colors.green[700],
    behavior: SnackBarBehavior.floating,
  ));
}
