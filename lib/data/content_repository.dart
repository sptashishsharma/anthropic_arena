import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/course.dart';

/// Where course/question content comes from.
///
/// The app ships with [AssetContentRepository] (bundled JSON, works offline).
/// When the Firebase project is created, add a FirestoreContentRepository
/// implementing this same interface and swap it in `providers.dart` —
/// nothing else in the app changes. See FIREBASE_SETUP.md.
abstract interface class ContentRepository {
  Future<List<Course>> loadCourses();
}

class AssetContentRepository implements ContentRepository {
  const AssetContentRepository();

  @override
  Future<List<Course>> loadCourses() async {
    final raw = await rootBundle.loadString('assets/content/courses.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final courses = ((json['courses'] as List?) ?? const [])
        .map((c) => Course.fromJson((c as Map).cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return courses;
  }
}
