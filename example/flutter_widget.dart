/// Flutter example: Transcript viewer widget.
///
/// Add to your pubspec.yaml:
///   dependencies:
///     youtubetranscript: ^0.1.0

import 'package:flutter/material.dart';
import 'package:youtubetranscript/youtubetranscript.dart';

class TranscriptViewer extends StatefulWidget {
  final String apiKey;
  final String videoId;

  const TranscriptViewer({
    super.key,
    required this.apiKey,
    required this.videoId,
  });

  @override
  State<TranscriptViewer> createState() => _TranscriptViewerState();
}

class _TranscriptViewerState extends State<TranscriptViewer> {
  late final YouTubeTranscript _yt;
  Transcript? _transcript;
  String? _error;
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _yt = YouTubeTranscript(widget.apiKey);
    _loadTranscript();
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  Future<void> _loadTranscript() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _yt.transcribe(widget.videoId);
      setState(() {
        _transcript = result;
        _loading = false;
      });
    } on NoCaptionsException {
      setState(() {
        _error = 'No captions available for this video';
        _loading = false;
      });
    } on YouTubeTranscriptException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<Segment> get _filteredSegments {
    if (_transcript == null) return [];
    if (_searchQuery.isEmpty) return _transcript!.segments;
    return _transcript!.search(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTranscript,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final segments = _filteredSegments;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                '${_transcript!.segments.length} segments · ${_transcript!.wordCount} words',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                _transcript!.language.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search transcript...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        const SizedBox(height: 8),

        // Segments list
        Expanded(
          child: ListView.builder(
            itemCount: segments.length,
            itemBuilder: (context, index) {
              final seg = segments[index];
              return ListTile(
                leading: Text(
                  seg.startFormatted,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                title: Text(seg.text),
                dense: true,
                onTap: () {
                  // Hook into your video player to seek to seg.start
                  print('Seek to ${seg.start}s');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
