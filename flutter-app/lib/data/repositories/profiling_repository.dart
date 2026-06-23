import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '_repo_support.dart';

class ProfilingRepository {
  ProfilingRepository(this._api);

  final ApiClient _api;

  /// POST /profiling/shams/chat — NLP extraction + draft upsert.
  Future<Map<String, dynamic>> chat(String message) async {
    final data = await _api.post(
      '/profiling/shams/chat',
      body: {
        'message': message,
      },
      timeout: AppConfig.profilingRequestTimeout,
    );
    final row = asRow(data);
    if (row == null) return const {};
    // Backend returns { reply, draft, preview } inside data.
    if (row.containsKey('preview') || row.containsKey('reply')) return row;
    final nested = row['data'];
    if (nested is Map<String, dynamic>) return nested;
    return row;
  }

  /// GET /profiling/drafts/me
  Future<Map<String, dynamic>?> myDraft() async {
    final data = await _api.get('/profiling/drafts/me');
    return asRow(data);
  }

  /// POST /profiling/drafts/confirm — persist profile and finish onboarding.
  Future<Map<String, dynamic>> confirmDraft() async {
    final data = await _api.post(
      '/profiling/drafts/confirm',
      body: {},
      timeout: AppConfig.profilingRequestTimeout,
    );
    return asRow(data) ?? const {};
  }

  /// POST /profiling/drafts/regenerate — clear draft for a fresh NLP pass.
  Future<void> regenerateDraft() async {
    await _api.post('/profiling/drafts/regenerate', body: {});
  }
}
