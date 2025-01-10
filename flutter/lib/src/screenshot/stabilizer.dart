import 'dart:async';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

import '../../sentry_flutter.dart';
import 'recorder.dart';
import 'screenshot.dart';

/// We're facing an issue: the tree walked with visitChildElements() is out of
/// sync to what is currently rendered by RenderRepaintBoundary.toImage(),
/// even though there's no async gap between these two. This causes masks to
/// be off during repaints, e.g. when scrolling a view or when text is rendered
/// in different places between two screens. This is most easily reproducible
/// when there's no animation between the two screens.
/// For example, Spotube's Search vs Library (2nd and 3rd bottom bar buttons).
///
/// To get around this issue, we're taking two subsequent screenshots
/// (after two frames) and only actually capture a screenshot if the
/// two are exactly the same.
@internal
class ScreenshotStabilizer<R> {
  final SentryFlutterOptions _options;
  final ScreenshotRecorder _recorder;
  final Future<R> Function(Screenshot screenshot) _callback;
  final int? maxTries;
  Screenshot? _previousScreenshot;
  int _tries = 0;
  bool stopped = false;

  ScreenshotStabilizer(this._recorder, this._options, this._callback,
      {this.maxTries}) {
    assert(maxTries == null || maxTries! > 1,
        "Cannot use ScreenshotStabilizer if we cannot retry at least once.");
  }

  void dispose() {
    _previousScreenshot?.dispose();
    _previousScreenshot = null;
  }

  void ensureFrameAndAddCallback(FrameCallback callback) {
    _options.bindingUtils.instance!
      ..ensureVisualUpdate()
      ..addPostFrameCallback(callback);
  }

  Future<void> capture(Duration _) {
    _tries++;
    return _recorder.capture(_onImageCaptured);
  }

  Future<void> _onImageCaptured(Screenshot screenshot) async {
    if (stopped) {
      _tries = 0;
      return;
    }

    final prevScreenshot = _previousScreenshot;
    try {
      _previousScreenshot = screenshot.clone();
      if (prevScreenshot != null &&
          await prevScreenshot.hasSameImageAs(screenshot)) {
        // Sucessfully captured a stable screenshot (repeated at least twice).
        _tries = 0;

        // If it's from the same (retry) flow, use the first screenshot
        // timestamp. Otherwise this was called from a scheduler (in a new flow)
        // so use the new timestamp.
        await _callback((prevScreenshot.flow.id == screenshot.flow.id)
            ? prevScreenshot
            : screenshot);

        // Do not just return the Future resulting from callback().
        // We need to await here so that the dispose runs ASAP.
        return;
      }
    } finally {
      // Note: we need to dispose (free the memory) before recursion.
      prevScreenshot?.dispose();
    }

    if (maxTries != null && _tries >= maxTries!) {
      throw Exception('Failed to capture a stable screenshot. '
          'Giving up after $_tries tries.');
    } else {
      // Add a delay to give the UI a chance to stabilize.
      // Only do this on every other frame so that there's a greater chance
      // of two subsequent frames being the same.
      final sleepMs = _tries % 2 == 1 ? min(100, 10 * (_tries - 1)) : 0;

      if (_tries > 1) {
        _options.logger(
            SentryLevel.debug,
            '${_recorder.logName}: '
            'Retrying screenshot capture due to UI changes. '
            'Delay before next capture: $sleepMs ms.');
      }

      if (sleepMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: sleepMs));
      }

      final completer = Completer<void>();
      ensureFrameAndAddCallback((Duration sinceSchedulerEpoch) async {
        _tries++;
        try {
          await _recorder.capture(_onImageCaptured, screenshot.flow);
          completer.complete();
        } catch (e, stackTrace) {
          completer.completeError(e, stackTrace);
        }
      });
      return completer.future;
    }
  }
}
