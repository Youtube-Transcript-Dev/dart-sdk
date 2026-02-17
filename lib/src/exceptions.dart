/// Exceptions thrown by the YouTubeTranscript SDK.
library;

/// Base exception for all API errors.
class YouTubeTranscriptException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const YouTubeTranscriptException(
    this.message, {
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'YouTubeTranscriptException: $message';
}

/// Invalid or missing API key (401).
class AuthenticationException extends YouTubeTranscriptException {
  const AuthenticationException(super.message, {super.statusCode, super.errorCode});
}

/// Not enough credits (402).
class InsufficientCreditsException extends YouTubeTranscriptException {
  const InsufficientCreditsException(super.message, {super.statusCode, super.errorCode});
}

/// Bad request — invalid parameters (400).
class InvalidRequestException extends YouTubeTranscriptException {
  const InvalidRequestException(super.message, {super.statusCode, super.errorCode});
}

/// Video has no captions and ASR not requested (404).
class NoCaptionsException extends YouTubeTranscriptException {
  const NoCaptionsException(super.message, {super.statusCode, super.errorCode});
}

/// Too many requests (429).
class RateLimitException extends YouTubeTranscriptException {
  final double? retryAfter;

  const RateLimitException(
    super.message, {
    this.retryAfter,
    super.statusCode,
    super.errorCode,
  });
}

/// Server-side error (5xx). Safe to retry.
class ServerException extends YouTubeTranscriptException {
  const ServerException(super.message, {super.statusCode, super.errorCode});
}

/// Thrown when an ASR job fails.
class JobFailedException extends YouTubeTranscriptException {
  final String jobId;
  const JobFailedException(super.message, {required this.jobId, super.statusCode, super.errorCode});
}

/// Thrown when polling times out.
class PollingTimeoutException extends YouTubeTranscriptException {
  const PollingTimeoutException(super.message);
}

/// Create the appropriate exception from an API error response.
YouTubeTranscriptException exceptionFromResponse(int statusCode, Map<String, dynamic> body) {
  final message = body['message'] as String? ?? body['error'] as String? ?? 'API error $statusCode';
  final errorCode = body['error_code'] as String?;

  switch (statusCode) {
    case 401:
      return AuthenticationException(message, statusCode: statusCode, errorCode: errorCode);
    case 402:
      return InsufficientCreditsException(message, statusCode: statusCode, errorCode: errorCode);
    case 404:
      return NoCaptionsException(message, statusCode: statusCode, errorCode: errorCode);
    case 429:
      final retryAfter = (body['retry_after'] as num?)?.toDouble();
      return RateLimitException(message, retryAfter: retryAfter, statusCode: statusCode, errorCode: errorCode);
    default:
      if (statusCode >= 500) {
        return ServerException(message, statusCode: statusCode, errorCode: errorCode);
      }
      return InvalidRequestException(message, statusCode: statusCode, errorCode: errorCode);
  }
}
