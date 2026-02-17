# youtubetranscript

Official Dart/Flutter SDK for [YouTubeTranscript.dev](https://youtubetranscript.dev) — extract, transcribe, and translate YouTube video transcripts.

## Installation

```yaml
dependencies:
  youtubetranscript: ^0.1.0
```

```bash
dart pub add youtubetranscript
```

## Quick Start

```dart
import 'package:youtubetranscript/youtubetranscript.dart';

final yt = YouTubeTranscript('your_api_key');

final result = await yt.transcribe('dQw4w9WgXcQ');

print('${result.segments.length} segments, ${result.wordCount} words');

for (final seg in result.segments) {
  print('[${seg.startFormatted}] ${seg.text}');
}

yt.close();
```

Get your free API key at [youtubetranscript.dev/dashboard](https://youtubetranscript.dev/dashboard)

## Features

### Translate

```dart
final spanish = await yt.transcribe('dQw4w9WgXcQ', language: 'es');
final japanese = await yt.transcribe('dQw4w9WgXcQ', language: 'ja');
```

### ASR Audio Transcription

For videos without captions:

```dart
final job = await yt.transcribeAsr('video_id');
final result = await yt.waitForJob(job.jobId); // polls until done
print(result.text);
```

### Batch Processing

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

### Search

```dart
final matches = result.search('keyword');
```

### Account Stats

```dart
final stats = await yt.stats();
print('Credits: ${stats.creditsRemaining}');
```

## Error Handling

```dart
try {
  final result = await yt.transcribe('video_id');
} on NoCaptionsException {
  // No captions — try ASR
  final job = await yt.transcribeAsr('video_id');
  final result = await yt.waitForJob(job.jobId);
} on AuthenticationException {
  print('Check your API key');
} on InsufficientCreditsException {
  print('Top up at youtubetranscript.dev/pricing');
} on RateLimitException catch (e) {
  print('Retry after ${e.retryAfter}s');
}
```

## Flutter Widget

See `example/flutter_widget.dart` for a ready-to-use `TranscriptViewer` widget with search, segment listing, and error handling.

```dart
TranscriptViewer(
  apiKey: 'your_api_key',
  videoId: 'dQw4w9WgXcQ',
)
```

## API Reference

| Method | Description |
|--------|-------------|
| `transcribe(video, {language, source, format})` | Extract transcript |
| `transcribeAsr(video, {language, webhookUrl})` | ASR audio transcription |
| `getJob(jobId)` | Check ASR job status |
| `waitForJob(jobId)` | Poll until complete |
| `batch(videoIds, {language})` | Batch extract (up to 100) |
| `getBatch(batchId)` | Check batch status |
| `listTranscripts({search, language})` | Browse history |
| `getTranscript(videoId)` | Get saved transcript |
| `stats()` | Account credits & usage |
| `deleteTranscript({videoId, ids})` | Delete transcripts |

## Credit Costs

| Operation | Cost |
|-----------|------|
| Captions extraction | 1 credit |
| Translation | 1 credit per 2,500 chars |
| ASR audio | 1 credit per 90 seconds |
| Re-fetch owned | Free |

## License

MIT — see [LICENSE](LICENSE)

## Links

- [Website](https://youtubetranscript.dev)
- [API Docs](https://youtubetranscript.dev/api-docs)
- [Dashboard](https://youtubetranscript.dev/dashboard)
- [Python SDK](https://pypi.org/project/youtubetranscript/)
