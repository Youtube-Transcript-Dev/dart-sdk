/// YouTubeTranscript API client for Dart/Flutter.
///
/// ```dart
/// final yt = YouTubeTranscript('your_api_key');
/// final result = await yt.transcribe('dQw4w9WgXcQ');
/// for (final seg in result.segments) {
///   print('[${seg.startFormatted}] ${seg.text}');
/// }
/// ```

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'models.dart';

/// The main client for interacting with the YouTubeTranscript.dev API.
class YouTubeTranscript {
  static const String _defaultBaseUrl = 'https://youtubetranscript.dev/api';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  final String _apiKey;
  final String _baseUrl;
  final Duration _timeout;
  final int _maxRetries;
  final http.Client _httpClient;
  final bool _ownsClient;

  /// Create a new YouTubeTranscript client.
  ///
  /// [apiKey] — Your API key from https://youtubetranscript.dev/dashboard
  /// [baseUrl] — API base URL (default: production).
  /// [timeout] — Request timeout duration.
  /// [maxRetries] — Number of retries on 5xx errors.
  /// [httpClient] — Custom HTTP client (for testing or proxies).
  YouTubeTranscript(
    String apiKey, {
    String baseUrl = _defaultBaseUrl,
    Duration timeout = _defaultTimeout,
    int maxRetries = 2,
    http.Client? httpClient,
  })  : _apiKey = apiKey.trim(),
        _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _timeout = timeout,
        _maxRetries = maxRetries,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null {
    if (_apiKey.length < 8) {
      throw ArgumentError(
        'Invalid API key. Get yours at https://youtubetranscript.dev/dashboard',
      );
    }
  }

  /// Close the HTTP client. Call when done.
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  // ─── Core Methods ──────────────────────────────────────────────

  /// Extract transcript from a YouTube video.
  ///
  /// [video] — YouTube URL or 11-character video ID.
  /// [language] — ISO 639-1 code (e.g. "es", "fr"). Omit for original.
  /// [source] — "auto" (default), "manual", or "asr".
  /// [format] — Format options map, e.g. `{"timestamp": true, "words": true}`.
  ///
  /// ```dart
  /// final result = await yt.transcribe('dQw4w9WgXcQ', language: 'es');
  /// print(result.text);
  /// ```
  Future<Transcript> transcribe(
    String video, {
    String? language,
    String? source,
    Map<String, bool>? format,
  }) async {
    final body = <String, dynamic>{'video': video};
    if (language != null) body['language'] = language;
    if (source != null) body['source'] = source;
    if (format != null) body['format'] = format;

    final data = await _post('/v2/transcribe', body);
    return Transcript.fromResponse(data);
  }

  /// Transcribe from audio using ASR (async operation).
  ///
  /// Cost: 1 credit per 90 seconds of audio.
  /// Returns a [TranscriptJob] with a job ID for polling.
  ///
  /// ```dart
  /// final job = await yt.transcribeAsr('video_id');
  /// final result = await yt.waitForJob(job.jobId);
  /// ```
  Future<TranscriptJob> transcribeAsr(
    String video, {
    String? language,
    String? webhookUrl,
  }) async {
    final body = <String, dynamic>{
      'video': video,
      'source': 'asr',
      'format': {'timestamp': true, 'paragraphs': true, 'words': true},
    };
    if (language != null) body['language'] = language;
    if (webhookUrl != null) body['webhook_url'] = webhookUrl;

    final data = await _post('/v2/transcribe', body);
    return TranscriptJob.fromResponse(data);
  }

  /// Check status of an ASR transcription job.
  Future<TranscriptJob> getJob(String jobId) async {
    final data = await _get('/v2/jobs/$jobId', queryParams: {
      'include_segments': 'true',
      'include_paragraphs': 'true',
      'include_words': 'true',
    });
    return TranscriptJob.fromResponse(data);
  }

  /// Poll an ASR job until completion.
  ///
  /// [pollInterval] — Duration between polls (default 10s).
  /// [timeout] — Max wait time (default 20 minutes).
  ///
  /// Throws [JobFailedException] if the job fails.
  /// Throws [TimeoutException] if polling exceeds timeout.
  Future<Transcript> waitForJob(
    String jobId, {
    Duration pollInterval = const Duration(seconds: 10),
    Duration timeout = const Duration(minutes: 20),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (true) {
      final job = await getJob(jobId);

      if (job.isComplete && job.transcript != null) {
        return job.transcript!;
      }

      if (job.isFailed) {
        throw JobFailedException(
          'ASR job $jobId failed: ${job.raw['error'] ?? 'unknown'}',
          jobId: jobId,
        );
      }

      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'Timed out waiting for job $jobId after ${timeout.inSeconds}s',
        );
      }

      await Future.delayed(pollInterval);
    }
  }

  /// Extract transcripts from up to 100 videos.
  ///
  /// ```dart
  /// final batch = await yt.batch(['video1', 'video2', 'video3']);
  /// for (final t in batch.completed) {
  ///   print('${t.videoId}: ${t.wordCount} words');
  /// }
  /// ```
  Future<BatchResult> batch(
    List<String> videoIds, {
    String? language,
  }) async {
    if (videoIds.length > 100) {
      throw ArgumentError('Maximum 100 videos per batch request');
    }

    final body = <String, dynamic>{'video_ids': videoIds};
    if (language != null) body['language'] = language;

    final data = await _post('/v2/batch', body);
    return BatchResult.fromResponse(data);
  }

  /// Check status of a batch request.
  Future<BatchResult> getBatch(String batchId) async {
    final data = await _get('/v2/batch/$batchId');
    return BatchResult.fromResponse(data);
  }

  // ─── V1 Endpoints (History & Stats) ────────────────────────────

  /// List your transcript history.
  Future<Map<String, dynamic>> listTranscripts({
    String? search,
    String? language,
    String? status,
    int limit = 10,
    int page = 1,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (search != null) params['search'] = search;
    if (language != null) params['language'] = language;
    if (status != null) params['status'] = status;

    return _get('/v1/history', queryParams: params);
  }

  /// Get a previously extracted transcript.
  Future<Transcript> getTranscript(
    String videoId, {
    String? language,
    String? source,
    bool includeTimestamps = true,
  }) async {
    final params = <String, String>{
      'include_timestamps': includeTimestamps.toString(),
    };
    if (language != null) params['language'] = language;
    if (source != null) params['source'] = source;

    final data = await _get('/v1/transcripts/$videoId', queryParams: params);
    return Transcript.fromResponse(data);
  }

  /// Get account stats: credits remaining, plan, usage.
  Future<AccountStats> stats() async {
    final data = await _get('/v1/stats');
    return AccountStats.fromResponse(data);
  }

  /// Delete transcripts by video ID or record IDs.
  Future<Map<String, dynamic>> deleteTranscript({
    String? videoId,
    List<String>? ids,
  }) async {
    final body = <String, dynamic>{};
    if (videoId != null) body['video_id'] = videoId;
    if (ids != null) body['ids'] = ids;
    return _post('/v1/transcripts/bulk-delete', body);
  }

  // ─── HTTP Layer ────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'User-Agent': 'youtubetranscript-dart/0.1.0',
      };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParams,
  }) =>
      _request('GET', path, queryParams: queryParams);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    YouTubeTranscriptException? lastException;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final http.Response response;

        if (method == 'POST') {
          response = await _httpClient
              .post(uri, headers: _headers, body: jsonEncode(body))
              .timeout(_timeout);
        } else {
          response = await _httpClient
              .get(uri, headers: _headers)
              .timeout(_timeout);
        }

        // Parse JSON
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          if (response.statusCode >= 400) {
            throw YouTubeTranscriptException(
              'Server returned ${response.statusCode}: ${response.body.substring(0, 200.clamp(0, response.body.length))}',
              statusCode: response.statusCode,
            );
          }
          throw const YouTubeTranscriptException('Invalid JSON in response');
        }

        // Check for errors
        if (response.statusCode >= 400 && response.statusCode != 202) {
          // Retry on 5xx
          if (response.statusCode >= 500 && attempt < _maxRetries) {
            lastException = null;
            await Future.delayed(Duration(seconds: 1 << attempt));
            continue;
          }
          throw exceptionFromResponse(response.statusCode, data);
        }

        return data;
      } on YouTubeTranscriptException {
        rethrow;
      } on TimeoutException {
        lastException = const YouTubeTranscriptException('Request timed out');
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        }
      } catch (e) {
        throw YouTubeTranscriptException('HTTP error: $e');
      }
    }

    throw lastException ?? const YouTubeTranscriptException('Request failed after retries');
  }
}
