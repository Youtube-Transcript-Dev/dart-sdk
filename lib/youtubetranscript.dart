/// Official Dart/Flutter SDK for YouTubeTranscript.dev
///
/// Extract, transcribe, and translate YouTube video transcripts.
///
/// ```dart
/// final yt = YouTubeTranscript('your_api_key');
/// final result = await yt.transcribe('dQw4w9WgXcQ');
/// print(result.text);
/// ```
///
/// Get your free API key at https://youtubetranscript.dev
library youtubetranscript;

export 'src/client.dart';
export 'src/models.dart';
export 'src/exceptions.dart';
