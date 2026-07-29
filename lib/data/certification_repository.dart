import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/certification.dart';

/// Where certification tracks + their practice question banks come from.
///
/// Ships with [AssetCertificationRepository] (bundled JSON, offline). Mirrors
/// the [ContentRepository] pattern: a FirestoreCertificationRepository can
/// implement this same interface later without touching the UI.
abstract interface class CertificationRepository {
  Future<List<Certification>> loadCertifications();
}

class AssetCertificationRepository implements CertificationRepository {
  const AssetCertificationRepository();

  @override
  Future<List<Certification>> loadCertifications() async {
    final raw =
        await rootBundle.loadString('assets/content/certifications.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final certs = ((json['certifications'] as List?) ?? const [])
        .map((c) => Certification.fromJson((c as Map).cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return certs;
  }
}
