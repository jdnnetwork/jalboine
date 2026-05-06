import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';
import '../models/senior_settings.dart';

final seniorSettingsProvider = StreamProvider<SeniorSettings>((ref) async* {
  final sb = ref.watch(supabaseProvider);
  final uid = sb.auth.currentUser?.id;
  if (uid == null) {
    yield SeniorSettings.empty;
    return;
  }
  final stream = sb
      .from('senior_settings')
      .stream(primaryKey: ['user_id']).eq('user_id', uid);
  await for (final rows in stream) {
    if (rows.isEmpty) {
      yield SeniorSettings.empty;
    } else {
      yield SeniorSettings.fromJson(rows.first);
    }
  }
});

final remoteSeniorSettingsProvider =
    StreamProvider.family<SeniorSettings, String>((ref, seniorId) async* {
  final sb = ref.watch(supabaseProvider);
  final stream = sb
      .from('senior_settings')
      .stream(primaryKey: ['user_id']).eq('user_id', seniorId);
  await for (final rows in stream) {
    if (rows.isEmpty) {
      yield SeniorSettings.empty;
      continue;
    }
    yield SeniorSettings.fromJson(rows.first);
  }
});
