import 'package:youtubetranscript/youtubetranscript.dart';

void main() async {
  final yt = YouTubeTranscript('your_api_key');

  try {
    // ─── Basic transcript extraction ──────────────────────────
    print('=== Basic Extraction ===');
    final result = await yt.transcribe('dQw4w9WgXcQ');
    print('Video: ${result.videoId}');
    print('Language: ${result.language}');
    print('Segments: ${result.segments.length}');
    print('Words: ${result.wordCount}');
    print('Duration: ${result.duration.toStringAsFixed(0)}s');
    print('');

    for (final seg in result.segments.take(5)) {
      print('[${seg.startFormatted}] ${seg.text}');
    }

    // ─── Translate ────────────────────────────────────────────
    print('\n=== Spanish Translation ===');
    final spanish = await yt.transcribe('dQw4w9WgXcQ', language: 'es');
    for (final seg in spanish.segments.take(3)) {
      print('[${seg.startFormatted}] ${seg.text}');
    }

    // ─── Export formats ───────────────────────────────────────
    print('\n=== SRT Export (first 3 segments) ===');
    final srt = result.toSrt();
    print(srt.split('\n').take(12).join('\n'));

    print('\n=== VTT Export ===');
    final vtt = result.toVtt();
    print(vtt.split('\n').take(8).join('\n'));

    // ─── Search ───────────────────────────────────────────────
    print('\n=== Search ===');
    final matches = result.search('never');
    print('Found ${matches.length} segments containing "never":');
    for (final m in matches.take(3)) {
      print('  [${m.startFormatted}] ${m.text}');
    }

    // ─── Batch (up to 100 videos) ─────────────────────────────
    print('\n=== Batch ===');
    final batch = await yt.batch(['dQw4w9WgXcQ', 'jNQXAC9IVRw']);
    for (final t in batch.completed) {
      print('  ${t.videoId}: ${t.wordCount} words');
    }

    // ─── ASR Audio Transcription ──────────────────────────────
    print('\n=== ASR (Audio Transcription) ===');
    final job = await yt.transcribeAsr('some_video_without_captions');
    print('Job ID: ${job.jobId}');
    print('Status: ${job.status}');

    // Poll until complete (up to 20 min)
    final asrResult = await yt.waitForJob(job.jobId);
    print('ASR complete: ${asrResult.wordCount} words');

    // ─── Account stats ────────────────────────────────────────
    print('\n=== Stats ===');
    final stats = await yt.stats();
    print('Plan: ${stats.plan}');
    print('Credits: ${stats.creditsRemaining}');

  } on NoCaptionsException {
    print('No captions available — try ASR instead');
  } on AuthenticationException {
    print('Invalid API key — check https://youtubetranscript.dev/dashboard');
  } on InsufficientCreditsException {
    print('Out of credits — top up at https://youtubetranscript.dev/pricing');
  } on RateLimitException catch (e) {
    print('Rate limited — retry after ${e.retryAfter}s');
  } on YouTubeTranscriptException catch (e) {
    print('API error: ${e.message}');
  } finally {
    yt.close();
  }
}
