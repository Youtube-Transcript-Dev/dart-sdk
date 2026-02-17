<p align="center">
  <a href="https://youtubetranscript.dev">
    <img src="https://youtubetranscript.dev/logo.svg" width="80" height="80" alt="YouTubeTranscript.dev logo" />
  </a>
</p>

<h1 align="center">youtubetranscript</h1>

<p align="center">
  <strong>Official Dart/Flutter SDK for <a href="https://youtubetranscript.dev">YouTubeTranscript.dev</a></strong><br />
  Extract, transcribe, and translate YouTube video transcripts with a single function call.
</p>

<p align="center">
  <a href="https://pub.dev/packages/youtubetranscript"><img src="https://img.shields.io/pub/v/youtubetranscript.svg" alt="pub version" /></a>
  <a href="https://pub.dev/packages/youtubetranscript/score"><img src="https://img.shields.io/badge/pub%20points-160%2F160-brightgreen" alt="pub points" /></a>
  <a href="https://pub.dev/packages/youtubetranscript"><img src="https://img.shields.io/pub/likes/youtubetranscript" alt="likes" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license" /></a>
</p>

---

## Why youtubetranscript?

- **Captions + ASR** — Extracts existing captions or transcribes audio when none are available
- **100+ languages** — Translate any transcript on the fly
- **Batch processing** — Up to 100 videos in a single request
- **Export anywhere** — SRT, WebVTT, plain text, timestamped text
- **Built-in search** — Find keywords across transcript segments
- **Typed exceptions** — Granular error handling with `NoCaptionsException`, `RateLimitException`, etc.
- **Automatic retries** — Resilient HTTP layer with configurable retry on 5xx errors
- **Flutter ready** — Works in any Dart app, ships with an example Flutter widget

## Installation

```bash
dart pub add youtubetranscript
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  youtubetranscript: ^0.1.0
```

## Quick Start

```dart
import 'package:youtubetranscript/youtubetranscript.dart';

void main() async {
  final yt = YouTubeTranscript('your_api_key');

  // Extract transcript
  final result = await yt.transcribe('dQw4w9WgXcQ');

  print('${result.segments.length} segments, ${result.wordCount} words');

  for (final seg in result.segments) {
    print('[${seg.startFormatted}] ${seg.text}');
  }

  yt.close();
}
```

> Get your free API key at [youtubetranscript.dev/dashboard](https://youtubetranscript.dev/dashboard)

## Features

### Translate to 100+ Languages

```dart
final spanish = await yt.transcribe('dQw4w9WgXcQ', language: 'es');
final japanese = await yt.transcribe('dQw4w9WgXcQ', language: 'ja');
```

### ASR Audio Transcription

For videos without captions — transcribe directly from audio:

```dart
final job = await yt.transcribeAsr('video_id');
final result = await yt.waitForJob(job.jobId); // polls until done
print(result.text);
```

### Batch Processing

Process up to 100 videos in one request:

```dart
final batch = await yt.batch(['video1', 'video2', 'video3']);
for (final t in batch.completed) {
  print('${t.videoId}: ${t.wordCount} words');
}
```

### Export Formats

```dart
result.toSrt();              // SRT subtitles
result.toVtt();              // WebVTT subtitles
result.toPlainText();        // Plain text
result.toTimestampedText();  // [MM:SS] text
```

### Search Within Transcripts

```dart
final matches = result.search('keyword');
for (final seg in matches) {
  print('[${seg.startFormatted}] ${seg.text}');
}
```

### Account Stats

```dart
final stats = await yt.stats();
print('Plan: ${stats.plan}');
print('Credits remaining: ${stats.creditsRemaining}');
```

## Error Handling

Every API error maps to a typed exception so you can handle each case precisely:

```dart
try {
  final result = await yt.transcribe('video_id');
} on NoCaptionsException {
  // No captions available — fall back to ASR
  final job = await yt.transcribeAsr('video_id');
  final result = await yt.waitForJob(job.jobId);
} on AuthenticationException {
  print('Invalid API key — check youtubetranscript.dev/dashboard');
} on InsufficientCreditsException {
  print('Out of credits — top up at youtubetranscript.dev/pricing');
} on RateLimitException catch (e) {
  print('Rate limited — retry after ${e.retryAfter}s');
} on YouTubeTranscriptException catch (e) {
  print('API error: ${e.message}');
}
```

## Flutter Widget

A ready-to-use `TranscriptViewer` widget is included in the examples — with search, segment listing, and error states:

```dart
TranscriptViewer(
  apiKey: 'your_api_key',
  videoId: 'dQw4w9WgXcQ',
)
```

See [`example/flutter_widget.dart`](example/flutter_widget.dart) for the full source.

## API Reference

| Method | Description |
|--------|-------------|
| `transcribe(video, {language, source, format})` | Extract transcript from a video |
| `transcribeAsr(video, {language, webhookUrl})` | Transcribe from audio (async) |
| `getJob(jobId)` | Check ASR job status |
| `waitForJob(jobId, {pollInterval, timeout})` | Poll until ASR job completes |
| `batch(videoIds, {language})` | Batch extract up to 100 videos |
| `getBatch(batchId)` | Check batch status |
| `listTranscripts({search, language})` | Browse transcript history |
| `getTranscript(videoId)` | Retrieve a saved transcript |
| `stats()` | Account credits & usage info |
| `deleteTranscript({videoId, ids})` | Delete transcripts |

## Credit Costs

| Operation | Cost |
|-----------|------|
| Captions extraction | 1 credit |
| Translation | 1 credit per 2,500 chars |
| ASR audio transcription | 1 credit per 90 seconds |
| Re-fetch owned transcript | Free |

## Other SDKs

| Language | Package |
|----------|---------|
| Python | [youtubetranscript on PyPI](https://pypi.org/project/youtubetranscript/) |
| JavaScript/Node | [youtubetranscript on npm](https://www.npmjs.com/package/youtubetranscript) |
| Dart/Flutter | **You are here** |

## License

MIT — see [LICENSE](LICENSE)

## Links

- [Website](https://youtubetranscript.dev)
- [API Documentation](https://youtubetranscript.dev/api-docs)
- [Dashboard & API Key](https://youtubetranscript.dev/dashboard)
- [GitHub](https://github.com/Youtube-Transcript-Dev/dart-sdk)
- [pub.dev](https://pub.dev/packages/youtubetranscript)
