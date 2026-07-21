import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_colors.dart';
import '../../utils/responsive.dart';

class VideoController extends GetxController {
  VideoPlayerController? videoPlayerController;

  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showControls = true.obs;
  final RxBool isFullscreen = false.obs;

  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;

  final RxDouble volume = 1.0.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  /// True jab tak naya quality controller initialize ho raha hai —
  /// widget isko chhota loading spinner dikhane ke liye use karta hai
  /// (pura black-screen restart jaisa nahi lagta).
  final RxBool isSwitchingQuality = false.obs;

  Timer? _hideControlsTimer;
  Timer? _positionTimer;

  /// Original URL passed to the player (master playlist / source url)
  String? _sourceUrl;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────
  Future<void> initializeVideo(String url) async {
    _sourceUrl = url;
    isInitialized.value = false;

    final newController = VideoPlayerController.networkUrl(Uri.parse(url));
    await newController.initialize();

    videoPlayerController = newController;
    totalDuration.value = newController.value.duration;

    newController.addListener(_videoListener);

    isInitialized.value = true;
    newController.play();
    isPlaying.value = true;

    _startHideControlsTimer();
    update();
  }

  void _videoListener() {
    if (videoPlayerController == null) return;
    final value = videoPlayerController!.value;

    currentPosition.value = value.position;
    totalDuration.value = value.duration;

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
  // ─────────────────────────────────────────────
  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
    // Actual orientation/fullscreen system UI change karna ho to yahan
    // SystemChrome calls add karo (aapke existing implementation ke hisaab se).
  }

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
  // QUALITY CHANGE — HLS (.m3u8) ke liye position-preserving switch
  // Non-HLS (.mp4 etc.) URLs ke liye bhi same URL replace logic try
  // karta hai; agar aapka backend alag naming deta hai to yahan
  // sirf `_buildQualityUrl` function edit karna hoga.
  // ─────────────────────────────────────────────
  Future<void> changeQuality(String quality, String originalUrl) async {
    if (videoPlayerController == null) return;

    final bool isHls = originalUrl.toLowerCase().contains(".m3u8");

    final String newUrl = _buildQualityUrl(
      originalUrl: originalUrl,
      quality: quality,
      isHls: isHls,
    );

    // Agar URL badla hi nahi (already same quality), to kuch mat karo
    if (newUrl == videoPlayerController!.dataSource) return;

    // 1. Current state save karo
    final Duration currentPos = videoPlayerController!.value.position;
    final bool wasPlaying = videoPlayerController!.value.isPlaying;
    final double currentVolume = volume.value;
    final double currentSpeed = playbackSpeed.value;

    final oldController = videoPlayerController;
    oldController?.removeListener(_videoListener);

    isSwitchingQuality.value = true;

    try {
      // 2. Naya controller banao aur initialize karo (background me)
      final newController = VideoPlayerController.networkUrl(Uri.parse(newUrl));
      await newController.initialize();

      // 3. Same position pe seek karo — YAHI restart-from-zero rokta hai
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

      // 4. Ab purana controller safely dispose karo
      await oldController?.dispose();

      _sourceUrl = quality == "Auto" ? originalUrl : newUrl;

      update();
    } catch (e) {
      // Naya controller fail hua to purane controller pe hi wapas chalo
      debugPrint("Quality change failed: $e");
      oldController?.addListener(_videoListener);
    } finally {
      isSwitchingQuality.value = false;
    }
  }

  /// Bunny CDN HLS URL pattern:
  /// master : https://vz-xxxxx.b-cdn.net/{video_id}/playlist.m3u8
  /// quality: https://vz-xxxxx.b-cdn.net/{video_id}/{res}p/video.m3u8
  ///
  /// ⚠️ Apni Bunny library ka actual sub-playlist naming pattern
  /// master playlist file khol ke verify kar lena — agar different
  /// hai to niche wali String replacement update kar dena.
  String _buildQualityUrl({
    required String originalUrl,
    required String quality,
    required bool isHls,
  }) {
    if (quality == "Auto" || !isHls) {
      return originalUrl;
    }

    final resolutionNumber = quality.replaceAll(RegExp(r'[^0-9]'), "");
    if (resolutionNumber.isEmpty) return originalUrl;

    if (originalUrl.contains("playlist.m3u8")) {
      return originalUrl.replaceFirst(
        "playlist.m3u8",
        "$resolutionNumber" "p/video.m3u8",
      );
    }

    // Agar URL already ek specific quality folder pe point kar raha hai
    // (jaise .../720p/video.m3u8), to us segment ko replace karo.
    final regex = RegExp(r'/\d+p/video\.m3u8');
    if (regex.hasMatch(originalUrl)) {
      return originalUrl.replaceFirst(regex, "/$resolutionNumber" "p/video.m3u8");
    }

    return originalUrl;
  }

  @override
  void onClose() {
    _hideControlsTimer?.cancel();
    _positionTimer?.cancel();
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
  final VideoController controller = Get.put(VideoController());
  final RxBool isLocked = false.obs;
  final RxString quality = "Auto".obs;

  @override
  void initState() {
    super.initState();
    controller.initializeVideo(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          children: [
            /// 🎬 VIDEO
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller
                      .videoPlayerController!
                      .value
                      .aspectRatio,
                  child: VideoPlayer(
                      controller.videoPlayerController!),
                ),
              ),
            ),

            /// 👆 TAPPABLE OVERLAY (Always active to catch mouse/touch events)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => controller.toggleControls(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

            /// 🔒 LOCK BUTTON
            Obx(() => controller.showControls.value ? Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.all(12),
                ),
                icon: Icon(
                  isLocked.value ? Icons.lock : Icons.lock_open,
                  color: isLocked.value ? AppColors.primary : Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  isLocked.value = !isLocked.value;
                  controller.showControls.value = true;
                  controller.toggleControls(); // Reset hide timer
                },
              ),
            ) : const SizedBox.shrink()),

            /// 🎮 CONTROLS
            Obx(() => controller.showControls.value && !isLocked.value
                ? Positioned.fill(child: _controls(context))
                : const SizedBox.shrink()),

            /// ⏳ QUALITY-SWITCH LOADING OVERLAY (chhota, video ke upar,
            /// pura restart jaisa feel nahi dega)
            Obx(() => controller.isSwitchingQuality.value
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
                : const SizedBox.shrink()),
          ],
        );
      }),
    );
  }

  /// 🎮 CONTROLS
  Widget _controls(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.toggleControls(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black45, // Slightly darker for better visibility
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
                        "Watch ${widget.title} on Nazar OTT: ${widget.url}",
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
                      final current = controller.videoPlayerController!.value.position;
                      controller.videoPlayerController!
                          .seekTo(current - const Duration(seconds: 10));
                    },
                  ),
                  const SizedBox(width: 40),
                  Obx(() => IconButton(
                    iconSize: 70,
                    icon: Icon(
                      controller.isPlaying.value
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: controller.togglePlay,
                  )),
                  const SizedBox(width: 40),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () {
                      final current = controller.videoPlayerController!.value.position;
                      controller.videoPlayerController!
                          .seekTo(current + const Duration(seconds: 10));
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    /// 🔥 SEEK BAR
                    Obx(() {
                      final total = controller.totalDuration.value.inSeconds;
                      final current = controller.currentPosition.value.inSeconds;

                      final progress = total == 0 ? 0.0 : current / total;

                      return Slider(
                        value: progress,
                        onChanged: controller.seekTo,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white30,
                      );
                    }),

                    /// ⏱ TIME + OPTIONS
                    Obx(() => Row(
                      children: [
                        Text(
                          "${_format(controller.currentPosition.value)} / ${_format(controller.totalDuration.value)}",
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(width: 20),

                        /// 🔊 VOLUME
                        const Icon(Icons.volume_up, color: Colors.white, size: 20),
                        SizedBox(
                          width: 100,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            ),
                            child: Slider(
                              value: controller.volume.value,
                              onChanged: controller.setVolume,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                            ),
                          ),
                        ),

                        const Spacer(),

                        /// ⚡ SPEED
                        IconButton(
                          icon: const Icon(Icons.speed, color: Colors.white),
                          onPressed: () => _showSpeedDialog(context),
                        ),

                        /// 🎬 QUALITY
                        IconButton(
                          icon: const Icon(Icons.hd, color: Colors.white),
                          onPressed: () => _showQualityDialog(context),
                        ),

                        /// 📺 FULLSCREEN
                        IconButton(
                          icon: Icon(
                            controller.isFullscreen.value
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: controller.toggleFullscreen,
                        ),
                      ],
                    )),
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
    String two(int n) =>
        n.toString().padLeft(2, "0");
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  /// ⚡ SPEED DIALOG
  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Speed"),
        children: [0.5, 1, 1.5, 2].map((e) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setPlaybackSpeed(e.toDouble());
              Navigator.pop(context);
            },
            child: Text("${e}x"),
          );
        }).toList(),
      ),
    );
  }

  /// 🎬 QUALITY DIALOG — UI bilkul same, sirf onPressed me
  /// changeQuality() call add hua jo position preserve karke switch karega
  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Quality"),
        children: ["Auto", "1080p", "720p", "480p"].map((q) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              quality.value = q;
              await controller.changeQuality(q, widget.url);
            },
            child: Text(q),
          );
        }).toList(),
      ),
    );
  }
}