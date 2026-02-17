import 'package:test/test.dart';
import 'package:youtubetranscript/youtubetranscript.dart';

void main() {
  group('Segment', () {
    test('fromJson basic', () {
      final s = Segment.fromJson({'text': 'Hello', 'start': 1.5, 'end': 3.0});
      expect(s.text, 'Hello');
      expect(s.start, 1.5);
      expect(s.end, 3.0);
      expect(s.duration, 1.5);
    });

    test('fromJson with duration computes end', () {
      final s = Segment.fromJson({'text': 'Hi', 'start': 0, 'duration': 2.5});
      expect(s.end, 2.5);
    });

    test('startFormatted', () {
      final s = Segment.fromJson({'text': '', 'start': 125.0});
      expect(s.startFormatted, '02:05');
    });

    test('startHms', () {
      final s = Segment.fromJson({'text': '', 'start': 3725.0});
      expect(s.startHms, '01:02:05');
    });
  });

  group('Transcript', () {
    test('fromResponse nested structure', () {
      final t = Transcript.fromResponse({
        'status': 'completed',
        'request_id': 'abc',
        'data': {
          'video_id': 'dQw4w9WgXcQ',
          'language': 'en',
          'transcript': {
            'text': 'Hello world',
            'segments': [
              {'text': 'Hello', 'start': 0, 'end': 1000},
              {'text': 'world', 'start': 1000, 'end': 2000},
            ]
          }
        }
      });
      expect(t.videoId, 'dQw4w9WgXcQ');
      expect(t.segments.length, 2);
      expect(t.segments[0].text, 'Hello');
      expect(t.language, 'en');
    });

    test('fromResponse flat segments', () {
      final t = Transcript.fromResponse({
        'data': {
          'video_id': 'test123',
          'segments': [
            {'text': 'one', 'start': 0, 'end': 1}
          ]
        }
      });
      expect(t.segments.length, 1);
    });

    test('toPlainText', () {
      final t = Transcript(
        videoId: 'x',
        segments: [
          Segment.fromJson({'text': 'Hello', 'start': 0}),
          Segment.fromJson({'text': 'world', 'start': 1}),
        ],
      );
      expect(t.toPlainText(), 'Hello world');
    });

    test('toSrt', () {
      final t = Transcript(
        videoId: 'x',
        segments: [Segment.fromJson({'text': 'Hello', 'start': 0, 'end': 1.5})],
      );
      final srt = t.toSrt();
      expect(srt, contains('1\n'));
      expect(srt, contains('00:00:00,000 --> 00:00:01,500'));
      expect(srt, contains('Hello'));
    });

    test('toVtt', () {
      final t = Transcript(
        videoId: 'x',
        segments: [Segment.fromJson({'text': 'Hi', 'start': 0, 'end': 2.0})],
      );
      final vtt = t.toVtt();
      expect(vtt, startsWith('WEBVTT'));
      expect(vtt, contains('00:00:00.000 --> 00:00:02.000'));
    });

    test('search case-insensitive', () {
      final t = Transcript(
        videoId: 'x',
        segments: [
          Segment.fromJson({'text': 'Hello world', 'start': 0}),
          Segment.fromJson({'text': 'Goodbye moon', 'start': 1}),
          Segment.fromJson({'text': 'Hello again', 'start': 2}),
        ],
      );
      expect(t.search('hello').length, 2);
      expect(t.search('MOON').length, 1);
    });

    test('wordCount', () {
      final t = Transcript(videoId: 'x', text: 'one two three four');
      expect(t.wordCount, 4);
    });

    test('duration from last segment', () {
      final t = Transcript(
        videoId: 'x',
        segments: [
          Segment.fromJson({'text': 'a', 'start': 0, 'end': 1}),
          Segment.fromJson({'text': 'b', 'start': 5, 'end': 10}),
        ],
      );
      expect(t.duration, 10.0);
    });
  });

  group('TranscriptJob', () {
    test('processing job', () {
      final j = TranscriptJob.fromResponse({
        'job_id': 'j123',
        'status': 'processing',
        'video_id': 'vid1',
      });
      expect(j.isProcessing, true);
      expect(j.isComplete, false);
      expect(j.transcript, isNull);
    });

    test('completed job has transcript', () {
      final j = TranscriptJob.fromResponse({
        'job_id': 'j123',
        'status': 'completed',
        'data': {
          'video_id': 'vid1',
          'transcript': {
            'segments': [
              {'text': 'hi', 'start': 0, 'end': 1}
            ]
          }
        }
      });
      expect(j.isComplete, true);
      expect(j.transcript, isNotNull);
      expect(j.transcript!.segments.length, 1);
    });

    test('failed job', () {
      final j = TranscriptJob.fromResponse({
        'job_id': 'j123',
        'status': 'failed',
      });
      expect(j.isFailed, true);
    });
  });

  group('BatchResult', () {
    test('fromResponse', () {
      final b = BatchResult.fromResponse({
        'batch_id': 'b1',
        'status': 'completed',
        'completed': [
          {
            'video_id': 'v1',
            'transcript': {
              'segments': [
                {'text': 'test', 'start': 0, 'end': 1}
              ]
            }
          }
        ],
        'failed': [],
      });
      expect(b.completed.length, 1);
      expect(b.completed[0].videoId, 'v1');
    });
  });

  group('AccountStats', () {
    test('fromResponse', () {
      final s = AccountStats.fromResponse({
        'credits_remaining': 42,
        'credits_used': 10,
        'plan': 'pro',
      });
      expect(s.creditsRemaining, 42);
      expect(s.plan, 'pro');
    });

    test('fromResponse with credits_left alias', () {
      final s = AccountStats.fromResponse({'credits_left': 99});
      expect(s.creditsRemaining, 99);
    });
  });

  group('Exceptions', () {
    test('401 → AuthenticationException', () {
      final e = exceptionFromResponse(401, {'message': 'Bad key'});
      expect(e, isA<AuthenticationException>());
      expect(e.statusCode, 401);
    });

    test('402 → InsufficientCreditsException', () {
      final e = exceptionFromResponse(402, {'message': 'No credits'});
      expect(e, isA<InsufficientCreditsException>());
    });

    test('404 → NoCaptionsException', () {
      final e = exceptionFromResponse(404, {'message': 'No captions'});
      expect(e, isA<NoCaptionsException>());
    });

    test('429 → RateLimitException with retryAfter', () {
      final e = exceptionFromResponse(429, {'message': 'Slow down', 'retry_after': 30});
      expect(e, isA<RateLimitException>());
      expect((e as RateLimitException).retryAfter, 30.0);
    });

    test('500 → ServerException', () {
      final e = exceptionFromResponse(500, {'message': 'Oops'});
      expect(e, isA<ServerException>());
    });

    test('400 → InvalidRequestException', () {
      final e = exceptionFromResponse(400, {'message': 'Bad input'});
      expect(e, isA<InvalidRequestException>());
    });
  });
}
