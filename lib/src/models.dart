/// Data models for the YouTubeTranscript API.

/// A single transcript segment with timing.
class Segment {
  final String text;
  final double start;
  final double end;
  final double duration;
  final List<Map<String, dynamic>>? words;

  const Segment({
    required this.text,
    required this.start,
    this.end = 0.0,
    this.duration = 0.0,
    this.words,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    final start = (json['start'] as num?)?.toDouble() ?? 0.0;
    final end = (json['end'] as num?)?.toDouble() ?? 0.0;
    final duration = (json['duration'] as num?)?.toDouble() ?? 0.0;

    return Segment(
      text: json['text'] as String? ?? '',
      start: start,
      end: end > 0 ? end : (duration > 0 ? start + duration : 0.0),
      duration: duration > 0 ? duration : (end > start ? end - start : 0.0),
      words: (json['words'] as List?)?.cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'start': start,
        'end': end,
        'duration': duration,
        if (words != null) 'words': words,
      };

  /// Format start time as MM:SS.
  String get startFormatted {
    final m = start ~/ 60;
    final s = (start % 60).toInt();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Format start time as HH:MM:SS.
  String get startHms {
    final h = start ~/ 3600;
    final rem = start.toInt() % 3600;
    final m = rem ~/ 60;
    final s = rem % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => '[$startFormatted] $text';
}

/// A complete video transcript.
class Transcript {
  final String videoId;
  final List<Segment> segments;
  final String text;
  final String language;
  final String status;
  final String requestId;
  final Map<String, dynamic> raw;

  const Transcript({
    required this.videoId,
    this.segments = const [],
    this.text = '',
    this.language = '',
    this.status = 'completed',
    this.requestId = '',
    this.raw = const {},
  });

  factory Transcript.fromResponse(Map<String, dynamic> data) {
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    final transcriptObj = inner['transcript'];

    List<dynamic> rawSegments = [];
    String fullText = '';

    if (transcriptObj is Map<String, dynamic>) {
      rawSegments = transcriptObj['segments'] as List? ?? [];
      fullText = transcriptObj['text'] as String? ?? '';
    } else if (transcriptObj is List) {
      rawSegments = transcriptObj;
    }

    // Fallback: segments at data level
    if (rawSegments.isEmpty) {
      rawSegments = inner['segments'] as List? ?? [];
    }

    final segments = rawSegments
        .map((s) => Segment.fromJson(s as Map<String, dynamic>))
        .toList();

    if (fullText.isEmpty && segments.isNotEmpty) {
      fullText = segments.map((s) => s.text).join(' ');
    }

    return Transcript(
      videoId: inner['video_id'] as String? ?? data['video_id'] as String? ?? '',
      segments: segments,
      text: fullText,
      language: inner['language'] as String? ?? data['language'] as String? ?? '',
      status: data['status'] as String? ?? 'completed',
      requestId: data['request_id'] as String? ?? '',
      raw: data,
    );
  }

  /// Total word count.
  int get wordCount => text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;

  /// Total duration in seconds based on last segment.
  double get duration {
    if (segments.isEmpty) return 0.0;
    final last = segments.last;
    return last.end > 0 ? last.end : last.start + last.duration;
  }

  /// Export as plain text.
  String toPlainText() => segments.map((s) => s.text).join(' ');

  /// Export as text with [MM:SS] timestamps.
  String toTimestampedText() =>
      segments.map((s) => '[${s.startFormatted}] ${s.text}').join('\n');

  /// Export as SRT subtitle format.
  String toSrt() {
    final buf = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final endTime = s.end > 0 ? s.end : s.start + (s.duration > 0 ? s.duration : 2.0);
      buf.writeln('${i + 1}');
      buf.writeln('${_srtTime(s.start)} --> ${_srtTime(endTime)}');
      buf.writeln(s.text);
      buf.writeln();
    }
    return buf.toString();
  }

  /// Export as WebVTT subtitle format.
  String toVtt() {
    final buf = StringBuffer();
    buf.writeln('WEBVTT');
    buf.writeln();
    for (final s in segments) {
      final endTime = s.end > 0 ? s.end : s.start + (s.duration > 0 ? s.duration : 2.0);
      buf.writeln('${_vttTime(s.start)} --> ${_vttTime(endTime)}');
      buf.writeln(s.text);
      buf.writeln();
    }
    return buf.toString();
  }

  /// Search segments containing query text (case-insensitive).
  List<Segment> search(String query) {
    final q = query.toLowerCase();
    return segments.where((s) => s.text.toLowerCase().contains(q)).toList();
  }

  @override
  String toString() => 'Transcript($videoId, ${segments.length} segments, $language)';
}

/// An async ASR transcription job.
class TranscriptJob {
  final String jobId;
  final String status;
  final String videoId;
  final Transcript? transcript;
  final Map<String, dynamic> raw;

  const TranscriptJob({
    required this.jobId,
    required this.status,
    this.videoId = '',
    this.transcript,
    this.raw = const {},
  });

  factory TranscriptJob.fromResponse(Map<String, dynamic> data) {
    Transcript? transcript;
    if (data['status'] == 'completed') {
      transcript = Transcript.fromResponse(data);
    }

    final inner = data['data'] as Map<String, dynamic>?;

    return TranscriptJob(
      jobId: data['job_id'] as String? ?? data['request_id'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      videoId: data['video_id'] as String? ?? inner?['video_id'] as String? ?? '',
      transcript: transcript,
      raw: data,
    );
  }

  bool get isComplete => status == 'completed';
  bool get isProcessing => status == 'processing' || status == 'queued';
  bool get isFailed => status == 'failed';

  @override
  String toString() => 'TranscriptJob($jobId, $status)';
}

/// Result of a batch transcription request.
class BatchResult {
  final String batchId;
  final String status;
  final List<Transcript> completed;
  final List<Map<String, dynamic>> failed;
  final Map<String, dynamic> raw;

  const BatchResult({
    required this.batchId,
    required this.status,
    this.completed = const [],
    this.failed = const [],
    this.raw = const {},
  });

  factory BatchResult.fromResponse(Map<String, dynamic> data) {
    final rawCompleted = data['completed'] as List? ?? data['data'] as List? ?? [];
    final completedList = rawCompleted
        .whereType<Map<String, dynamic>>()
        .map((item) => Transcript.fromResponse(item))
        .toList();

    return BatchResult(
      batchId: data['batch_id'] as String? ?? '',
      status: data['status'] as String? ?? 'completed',
      completed: completedList,
      failed: (data['failed'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      raw: data,
    );
  }

  @override
  String toString() => 'BatchResult($batchId, ${completed.length} completed)';
}

/// Account usage statistics.
class AccountStats {
  final int creditsRemaining;
  final int creditsUsed;
  final int transcriptsCreated;
  final String plan;
  final Map<String, dynamic> raw;

  const AccountStats({
    this.creditsRemaining = 0,
    this.creditsUsed = 0,
    this.transcriptsCreated = 0,
    this.plan = '',
    this.raw = const {},
  });

  factory AccountStats.fromResponse(Map<String, dynamic> data) {
    return AccountStats(
      creditsRemaining: data['credits_remaining'] as int? ?? data['credits_left'] as int? ?? 0,
      creditsUsed: data['credits_used'] as int? ?? 0,
      transcriptsCreated: data['transcripts_created'] as int? ?? 0,
      plan: data['plan'] as String? ?? '',
      raw: data,
    );
  }

  @override
  String toString() => 'AccountStats($plan, $creditsRemaining credits)';
}

// ─── Helpers ──────────────────────────────────────────────────────

String _srtTime(double seconds) {
  final h = seconds ~/ 3600;
  final rem = seconds.toInt() % 3600;
  final m = rem ~/ 60;
  final s = rem % 60;
  final ms = ((seconds - seconds.toInt()) * 1000).round();
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')},${ms.toString().padLeft(3, '0')}';
}

String _vttTime(double seconds) {
  final h = seconds ~/ 3600;
  final rem = seconds.toInt() % 3600;
  final m = rem ~/ 60;
  final s = rem % 60;
  final ms = ((seconds - seconds.toInt()) * 1000).round();
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
}
