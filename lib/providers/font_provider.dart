import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Font index provider - controls which font pair is active
final fontIndexProvider = StateProvider<int>((ref) => 0);
