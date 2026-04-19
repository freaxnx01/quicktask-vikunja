import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Thin wrapper around [ReceiveSharingIntent] so the share-intent plumbing is
/// injectable in widget tests.
abstract class ShareIntentSource {
  Stream<List<SharedMediaFile>> getMediaStream();
  Future<List<SharedMediaFile>> getInitialMedia();
  void reset();
}

class DefaultShareIntentSource implements ShareIntentSource {
  const DefaultShareIntentSource();

  @override
  Stream<List<SharedMediaFile>> getMediaStream() =>
      ReceiveSharingIntent.instance.getMediaStream();

  @override
  Future<List<SharedMediaFile>> getInitialMedia() =>
      ReceiveSharingIntent.instance.getInitialMedia();

  @override
  void reset() => ReceiveSharingIntent.instance.reset();
}
