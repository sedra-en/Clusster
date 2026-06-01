// ============================================================
// 🔑 App Global Keys
// المكان: lib/core/app_keys.dart
// ============================================================
// ملف مستقل للمفاتيح العالمية — يُستورد من أي مكان بدون
// circular imports
// ============================================================

import 'package:flutter/material.dart';

/// مفتاح الملاحة — للتنقل بين الشاشات من أي مكان
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

/// مفتاح ScaffoldMessenger — لعرض Snackbar من أي شاشة
final GlobalKey<ScaffoldMessengerState> appScaffoldKey =
    GlobalKey<ScaffoldMessengerState>();