import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_colors.dart';
import '../../utils/responsive.dart';

class VideoController extends GetxController {
  VideoPlayerController? videoPlayerController;

  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final RxBool showControls = true.obs;
  final RxBool isFullscreen = false.obs;

  /// NEW: surfaced error state so the UI can show something instead of
  /// spinning forever when a stream fails to load/play.
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;

  final RxDouble volume = 1.0.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  /// True while a new quality controller is initializing — widget shows a
  /// small spinner over the video instead of a full black-screen restart.
  final RxBool isSwitchingQuality = false.obs;

  final RxInt playerVersion = 0.obs;

  Timer? _hideControlsTimer;

  /// Original URL passed to the player (master playlist / source url)
  String? _sourceUrl;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────
  Future<void> initializeVideo(String url) async {
    _sourceUrl = url;
    isInitialized.value = false;
    hasError.value = false;
    errorMessage.value = '';

    if (kIsWeb && url.toLowerCase().contains('.m3u8')) {
      // video_player on Flutter Web uses the browser's native <video> tag,
      // which does NOT support HLS except in Safari. This is a platform
      // limitation, not a bug you can fix here — you need an hls.js-backed
      // web player (or a dedicated web video plugin) for HLS on web.
      hasError.value = true;
      errorMessage.value =
          'HLS (.m3u8) playback is not supported on this browser. '
          'Please use the mobile/desktop app, or Safari.';
      return;
    }

    try {
      final bool isHls = url.toLowerCase().contains('.m3u8');

      final newController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        // Explicit format hint — without this, ExoPlayer on Android can
        // mis-detect the container when the CDN redirects the URL or omits
        // a clean file extension, and playback fails silently.
        formatHint: isHls ? VideoFormat.hls : VideoFormat.other,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        // Chrome opens this exact URL fine but ExoPlayer gets a 403 —
        // that rules out referrer/token restrictions (a plain address-bar
        // navigation sends no Referer either) and points to User-Agent
        // based bot detection instead. ExoPlayer's default UA
        // ("AndroidXMedia3/... ExoPlayerLib/...") looks nothing like a
        // browser, so a WAF/CDN in front of Bunny blocks it. Spoofing a
        // real browser UA works around that.
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        },
      );

      await newController.initialize();

      videoPlayerController = newController;
      totalDuration.value = newController.value.duration;

      newController.addListener(_videoListener);

      isInitialized.value = true;
      hasError.value = false;
      playerVersion.value++;
      await newController.play();
      isPlaying.value = true;

      _startHideControlsTimer();
      update();
    } catch (e, st) {
      debugPrint('Video init error: $e');
      debugPrintStack(stackTrace: st);
      isInitialized.value = false;
      hasError.value = true;
      errorMessage.value = 'Unable to play this video. Please try again.';
    }
  }

  /// Retry after a failure, using the last known source url.
  Future<void> retry() async {
    if (_sourceUrl == null) return;
    await initializeVideo(_sourceUrl!);
  }

  void _videoListener() {
    if (videoPlayerController == null) return;
    final value = videoPlayerController!.value;

    // NEW: surface mid-playback errors (segment fetch failures, stream
    // drops, decoder errors) instead of ignoring them.
    if (value.hasError) {
      hasError.value = true;
      errorMessage.value = value.errorDescription ?? 'Playback error.';
      isPlaying.value = false;
      return;
    }

    currentPosition.value = value.position;
    totalDuration.value = value.duration;
    isBuffering.value = value.isBuffering;

    if (isPlaying.value != value.isPlaying) {
      isPlaying.value = value.isPlaying;
    }
  }

  // ─────────────────────────────────────────────
  // PLAY / PAUSE
  // ─────────────────────────────────────────────
  void togglePlay() {
    if (videoPlayerController == null) return;
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
      isPlaying.value = false;
    } else {
      videoPlayerController!.play();
      isPlaying.value = true;
    }
    _resetHideControlsTimer();
  }

  // ─────────────────────────────────────────────
  // SEEK (slider uses 0.0 - 1.0 progress)
  // ─────────────────────────────────────────────
  void seekTo(double progress) {
    if (videoPlayerController == null) return;
    final total = videoPlayerController!.value.duration;
    final newPosition = total * progress;
    videoPlayerController!.seekTo(newPosition);
    _resetHideControlsTimer();
  }

  // ─────────────────────────────────────────────
  // VOLUME
  // ─────────────────────────────────────────────
  void setVolume(double value) {
    volume.value = value;
    videoPlayerController?.setVolume(value);
  }

  // ─────────────────────────────────────────────
  // SPEED
  // ─────────────────────────────────────────────
  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    videoPlayerController?.setPlaybackSpeed(speed);
  }

  // ─────────────────────────────────────────────
  // FULLSCREEN
  // NOTE: actual SystemChrome orientation/UI-mode calls now live in
  // _AdvancedVideoPlayerState (_enterFullscreen/_exitFullscreen) since
  // those are platform/UI side effects tied to this specific page's
  // lifecycle, not something the controller should own. This just tracks
  // the boolean state for the icon.
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // CONTROLS SHOW/HIDE
  // ─────────────────────────────────────────────
  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _resetHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      showControls.value = false;
    });
  }

  void _resetHideControlsTimer() {
    if (showControls.value) {
      _startHideControlsTimer();
    }
  }

  // ─────────────────────────────────────────────
  // QUALITY CHANGE
  //
  // IMPORTANT: Bunny Stream's master playlist (playlist.m3u8) is normally
  // ADAPTIVE — it already lists every bitrate internally via
  // #EXT-X-STREAM-INF, and the player auto-switches based on bandwidth.
  // Manually rewriting the URL to "{res}p/video.m3u8" ONLY works if your
  // Bunny library actually serves separate per-resolution playlists at
  // that exact path. If it doesn't, every switch 404s.
  //
  // Verify your real sub-playlist naming by opening the master
  // playlist.m3u8 in a text editor / browser — look for lines like:
  //   #EXT-X-STREAM-INF:BANDWIDTH=...,RESOLUTION=1280x720
  //   720p/video.m3u8
  // and adjust _buildQualityUrl to match exactly what you see there.
  // ─────────────────────────────────────────────
  Future<bool> changeQuality(String quality, String originalUrl) async {
    if (videoPlayerController == null) return false;

    final bool isHls = originalUrl.toLowerCase().contains('.m3u8');

    final String newUrl = _buildQualityUrl(
      originalUrl: originalUrl,
      quality: quality,
      isHls: isHls,
    );

    // URL didn't change (already this quality, or unsupported combo) —
    // nothing to do.
    if (newUrl == videoPlayerController!.dataSource) return true;

    // 1. Save current state
    final Duration currentPos = videoPlayerController!.value.position;
    final bool wasPlaying = videoPlayerController!.value.isPlaying;
    final double currentVolume = volume.value;
    final double currentSpeed = playbackSpeed.value;

    final oldController = videoPlayerController;
    oldController?.removeListener(_videoListener);

    isSwitchingQuality.value = true;

    try {
      // 2. Build + initialize the new controller in the background
      final newController = VideoPlayerController.networkUrl(
        Uri.parse(newUrl),
        formatHint: isHls ? VideoFormat.hls : VideoFormat.other,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        },
      );
      await newController.initialize();

      // 3. Seek to the same position — this is what prevents a
      // restart-from-zero on quality switch.
      await newController.seekTo(currentPos);
      await newController.setVolume(currentVolume);
      await newController.setPlaybackSpeed(currentSpeed);

      newController.addListener(_videoListener);

      videoPlayerController = newController;
      totalDuration.value = newController.value.duration;
      currentPosition.value = currentPos;

      if (wasPlaying) {
        await newController.play();
      }
      isPlaying.value = wasPlaying;
      hasError.value = false;
      // This is what fixes the black screen: without bumping this, Obx
      // never knows the underlying controller instance changed and keeps
      // showing the disposed one.
      playerVersion.value++;

      // 4. Now it's safe to dispose the old controller
      await oldController?.dispose();

      _sourceUrl = quality == 'Auto' ? originalUrl : newUrl;

      update();
      return true;
    } catch (e, st) {
      // New quality URL failed (commonly a 404 because that resolution
      // playlist doesn't actually exist) — fall back to the old
      // controller so playback doesn't just die.
      debugPrint('Quality change failed: $e');
      debugPrintStack(stackTrace: st);
      oldController?.addListener(_videoListener);
      return false;
    } finally {
      isSwitchingQuality.value = false;
    }
  }

  /// Bunny CDN HLS URL pattern (VERIFY against your actual master
  /// playlist — see note above changeQuality()):
  /// master : https://vz-xxxxx.b-cdn.net/{video_id}/playlist.m3u8
  /// quality: https://vz-xxxxx.b-cdn.net/{video_id}/{res}p/video.m3u8
  String _buildQualityUrl({
    required String originalUrl,
    required String quality,
    required bool isHls,
  }) {
    if (quality == 'Auto' || !isHls) {
      return originalUrl;
    }

    final resolutionNumber = quality.replaceAll(RegExp(r'[^0-9]'), '');
    if (resolutionNumber.isEmpty) return originalUrl;

    if (originalUrl.contains('playlist.m3u8')) {
      return originalUrl.replaceFirst(
        'playlist.m3u8',
        '${resolutionNumber}p/video.m3u8',
      );
    }

    // If URL already points at a specific quality folder
    // (e.g. .../720p/video.m3u8), replace that segment.
    final regex = RegExp(r'/\d+p/video\.m3u8');
    if (regex.hasMatch(originalUrl)) {
      return originalUrl.replaceFirst(
        regex,
        '/${resolutionNumber}p/video.m3u8',
      );
    }

    return originalUrl;
  }

  @override
  void onClose() {
    _hideControlsTimer?.cancel();
    videoPlayerController?.removeListener(_videoListener);
    videoPlayerController?.dispose();
    super.onClose();
  }
}

class AdvancedVideoPlayer extends StatefulWidget {
  final String url;
  final String title;

  const AdvancedVideoPlayer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AdvancedVideoPlayer> createState() => _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState extends State<AdvancedVideoPlayer> {
  // NEW: tag the controller with the url so navigating between different
  // videos never accidentally reuses a stale controller/player instance.
  late final String _tag = widget.url;
  late final VideoController controller = Get.put(VideoController(), tag: _tag);

  final RxBool isLocked = false.obs;
  final RxString quality = 'Auto'.obs;

  @override
  void initState() {
    super.initState();
    controller.initializeVideo(widget.url);
  }

  @override
  void dispose() {
    // Always restore portrait + system bars when leaving this page —
    // otherwise a fullscreen/landscape lock leaks into every other screen
    // in the app.
    _restoreSystemUi();

    // NEW: remove this controller from GetX so the next video page gets a
    // fresh instance instead of a disposed/stale one.
    Get.delete<VideoController>(tag: _tag);
    super.dispose();
  }

  /// Locks to landscape and hides status/nav bars for a real fullscreen
  /// video experience.
  void _enterFullscreen() {
    controller.isFullscreen.value = true;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Reverts back to portrait and restores the status/nav bars.
  void _exitFullscreen() {
    controller.isFullscreen.value = false;
    _restoreSystemUi();
  }

  void _restoreSystemUi() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.hasError.value) {
          return _errorView();
        }

        if (!controller.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            /// 🎬 VIDEO
            /// Dedicated Obx reading `playerVersion` — this is what makes
            /// the widget rebuild against the new controller instance
            /// after a quality switch (fixes the black screen).
            Obx(() {
              // ignore: unused_local_variable
              final _version = controller.playerVersion.value;
              return Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                        controller.videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(controller.videoPlayerController!),
                  ),
                ),
              );
            }),

            /// ⏳ BUFFERING INDICATOR
            Obx(
              () => controller.isBuffering.value
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const SizedBox.shrink(),
            ),

            /// 👆 TAPPABLE OVERLAY (Always active to catch mouse/touch events)
            /// When locked, only the lock button area can be tapped
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Don't toggle controls if locked
                  if (!isLocked.value) {
                    controller.toggleControls();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

            /// 🔒 LOCK BUTTON - Always visible and tappable even when locked
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: GestureDetector(
                onTap: () {
                  // Toggle lock state - this always works
                  isLocked.value = !isLocked.value;
                  // When unlocking, show controls briefly
                  if (!isLocked.value) {
                    controller.showControls.value = true;
                    controller.toggleControls(); // Reset hide timer
                  } else {
                    // When locking, hide controls immediately
                    controller.showControls.value = false;
                    controller._hideControlsTimer?.cancel();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isLocked.value ? Icons.lock : Icons.lock_open,
                    color: isLocked.value ? AppColors.primary : Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

            /// 🎮 CONTROLS - Only show when not locked
            Obx(
              () => !isLocked.value && controller.showControls.value
                  ? Positioned.fill(child: _controls(context))
                  : const SizedBox.shrink(),
            ),

            /// 🔒 LOCKED OVERLAY MESSAGE - Show when locked
            Obx(
              () => isLocked.value
                  ? Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap 🔒 to unlock',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            /// ⏳ QUALITY-SWITCH LOADING OVERLAY
            Obx(
              () => controller.isSwitchingQuality.value
                  ? const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black26,
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }),
    );
  }

  /// ❌ ERROR VIEW — shown instead of an infinite spinner when playback
  /// fails to initialize or errors out mid-stream.
  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => controller.retry(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🎮 CONTROLS
  Widget _controls(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Only toggle controls if not locked
        if (!isLocked.value) {
          controller.toggleControls();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black45,
        child: Column(
          children: [
            /// 🔝 TOP BAR
            SafeArea(
              child: Row(
                children: [
                  Responsive.backButton(context, onPressed: () => Get.back()),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      Share.share(
                        'Watch ${widget.title} on Nazar OTT: ${widget.url}',
                        subject: widget.title,
                      );
                    },
                  ),
                ],
              ),
            ),

            /// ▶️ CENTER PLAY
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () {
                      if (!isLocked.value) {
                        final current =
                            controller.videoPlayerController!.value.position;
                        controller.videoPlayerController!.seekTo(
                          current - const Duration(seconds: 10),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 40),
                  Obx(
                    () => IconButton(
                      iconSize: 70,
                      icon: Icon(
                        controller.isPlaying.value
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (!isLocked.value) {
                          controller.togglePlay();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () {
                      if (!isLocked.value) {
                        final current =
                            controller.videoPlayerController!.value.position;
                        controller.videoPlayerController!.seekTo(
                          current + const Duration(seconds: 10),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            /// ⬇ BOTTOM CONTROLS
            SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    /// 🔥 SEEK BAR
                    Obx(() {
                      final total = controller.totalDuration.value.inSeconds;
                      final current =
                          controller.currentPosition.value.inSeconds;
                      final progress = total == 0 ? 0.0 : current / total;

                      return Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          if (!isLocked.value) {
                            controller.seekTo(value);
                          }
                        },
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white30,
                      );
                    }),

                    /// ⏱ TIME + OPTIONS
                    Obx(
                      () => Row(
                        children: [
                          Text(
                            '${_format(controller.currentPosition.value)} / ${_format(controller.totalDuration.value)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 20),

                          /// 🔊 VOLUME
                          const Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.25,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10,
                                ),
                              ),
                              child: Slider(
                                value: controller.volume.value,
                                onChanged: (value) {
                                  if (!isLocked.value) {
                                    controller.setVolume(value);
                                  }
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.white24,
                              ),
                            ),
                          ),

                          const Spacer(),

                          /// ⚡ SPEED
                          IconButton(
                            icon: const Icon(Icons.speed, color: Colors.white),
                            onPressed: () {
                              if (!isLocked.value) {
                                _showSpeedDialog(context);
                              }
                            },
                          ),

                          /// 🎬 QUALITY
                          IconButton(
                            icon: const Icon(Icons.hd, color: Colors.white),
                            onPressed: () {
                              if (!isLocked.value) {
                                _showQualityDialog(context);
                              }
                            },
                          ),

                          /// 📺 FULLSCREEN
                          IconButton(
                            icon: Icon(
                              controller.isFullscreen.value
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (!isLocked.value) {
                                if (controller.isFullscreen.value) {
                                  _exitFullscreen();
                                } else {
                                  _enterFullscreen();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⏱ FORMAT
  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  /// ⚡ SPEED DIALOG
  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Speed'),
        children: [0.5, 1, 1.5, 2].map((e) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setPlaybackSpeed(e.toDouble());
              Navigator.pop(context);
            },
            child: Text('${e}x'),
          );
        }).toList(),
      ),
    );
  }

  /// 🎬 QUALITY DIALOG
  /// FIXED: reverts the selected quality label if the switch fails, and
  /// shows a snackbar so the user isn't left with a mismatched UI state.
  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Quality'),
        children: ['Auto', '1080p', '720p', '480p'].map((q) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final previousQuality = quality.value;
              quality.value = q;

              final success = await controller.changeQuality(q, widget.url);

              if (!success) {
                // Revert UI state so it matches what's actually playing.
                quality.value = previousQuality;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$q is not available for this video.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              }
            },
            child: Text(q),
          );
        }).toList(),
      ),
    );
  }
}
