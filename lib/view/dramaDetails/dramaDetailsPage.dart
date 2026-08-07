// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nazar_ott/view/homePages/mainHomepage.dart';
import '../../app/routes/app_routes.dart';
import '../../utils/responsive.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/download_controller/download_controller.dart';
import '../../view_model/primium_controller/premium_controller.dart';
import '../../widgets/custom_network_image.dart';
import '../../widgets/golden_button.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../view_model/content_controller/content_controller.dart';
import '../../view_model/like_dislike_controller/like_dislike_controller.dart';
import '../../view_model/watchlist_controller/watchlist_controller.dart';
import '../../widgets/golden_text.dart';
import '../popUp/age_popup.dart';
import '../../utils/share_service.dart';
import '../../view_model/drama_detail_controller/drama_details_controller.dart';
import '../../utils/custom_snackbar.dart';

class DramaDetailsPage extends StatefulWidget {
  final bool isSignedIn;
  final ContentModel content;
  final String? id;
  const DramaDetailsPage({
    super.key,
    required this.isSignedIn,
    required this.content,
    this.id,
  });

  @override
  State<DramaDetailsPage> createState() => _DramaDetailsPageState();
}

class _DramaDetailsPageState extends State<DramaDetailsPage> {
  final DramaDetailsController controller = Get.put(DramaDetailsController());
  final AuthController authController = Get.find<AuthController>();
  final WatchlistController watchlistController = Get.put(
    WatchlistController(),
  );
  final ContentController contentController = Get.put(ContentController());
  final PremiumController premiumController = Get.put(PremiumController());
  final InteractionController interactionController = Get.put(
    InteractionController(),
  );
  final DownloadController downloadController = Get.put(DownloadController());

  /// Resolves which content model to display:
  /// - If an `id` was passed AND the detail fetch has completed, use that.
  /// - Otherwise, fall back to the `content` passed directly to the widget.
  ContentModel get content {
    if (widget.id != null && contentController.contentDetail.value != null) {
      return contentController.contentDetail.value!;
    }
    return widget.content;
  }

  /// The real, resolved content id — from the fetched detail (if widget.id
  /// was provided and detail loaded) or from the ContentModel passed in.
  /// Always use this (not widget.id) when forwarding an id, e.g. to SignInPage.
  String get contentId => content.id;

  @override
  void initState() {
    super.initState();
    interactionController.fetchStatus(widget.content.id);
    if (authController.isLoggedIn.value &&
        watchlistController.watchlist.isEmpty) {
      watchlistController.getWatchlist();
    }
    if (widget.content.contentType == 'series') {
      contentController.fetchEpisodes(widget.content.id);
    }

    if (widget.id != null) {
      contentController.fetchContentDetail(widget.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Responsive.backButton(
          context,
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: ((context) => MainHomePage())));
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Obx(() {
          final ContentModel data = content;

          final List<ContentModel> relatedContent = contentController.allContent
              .where((item) {
                String normalize(String s) =>
                    s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
                return item.id != data.id &&
                    item.contentType == data.contentType &&
                    item.category.any((cat) => data.category.any((dataCat) =>
                        normalize(dataCat) == normalize(cat)));
              })
              .toList();

          return Column(
            children: [
              /// 🎬 CINEMATIC HERO SECTION
              _buildHeroSection(isDesktop),

              /// 📖 CONTENT AREA
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 60 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        /// WATCH & DOWNLOAD BUTTONS (Moved here from Banner)
                        if (data.contentType != 'series') ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildWatchButton(isDesktop: isDesktop),
                              ),
                              if (!kIsWeb) ...[
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildMainDownloadButton(
                                    isDesktop: isDesktop,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 25),
                        ],

                        /// DESCRIPTION & INFO (Mobile Only or additional)
                        if (!isDesktop) ...[
                          Text(
                            data.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSmallActionsRow(),
                          const SizedBox(height: 20),
                        ],

                        /// 📺 SEASONS & EPISODES
                        if (data.contentType == 'series')
                          _buildEpisodesSection(context, isDesktop),

                        const SizedBox(height: 30),

                        /// 🎭 CAST & CREW
                        if (data.cast != null && data.cast!.isNotEmpty)
                          _buildCastSection(isDesktop),

                        const SizedBox(height: 30),

                        /// ❤️ MORE LIKE THIS
                        if (relatedContent.isNotEmpty)
                          _buildRelatedSection(relatedContent, isDesktop),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 750 : 350,
      color: Colors.black,
      child: Stack(
        children: [
          /// THE ACTUAL BANNER
          CustomNetworkImage(
            imageUrl: content.banner,
            width: double.infinity,
            height: isDesktop ? 750 : 350,
            fit: BoxFit.fill,
          ),

          /// SUBTLE GRADIENT OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black,
                ],
                stops: const [0.7, 0.9, 1.0],
              ),
            ),
          ),

          /// INFO OVERLAY
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 60 : 20,
              vertical: 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 42 : 24,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "${content.releaseYear} • ${content.language}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 16 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (content.duration != null) ...[
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          content.duration!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                if (isDesktop)
                  SizedBox(
                    width: 700,
                    child: Text(
                      content.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 5),

                /// TRAILER & SMALL ACTIONS (Watch Now removed from here)
                Row(children: [if (isDesktop) _buildSmallActionsRow()]),
              ],
            ),
          ),

          /// TRAILER BUTTON AT BOTTOM RIGHT
          if (content.trailerUrl != null && content.trailerUrl!.isNotEmpty)
            Positioned(
              bottom: 10,
              right: 10,
              child: _buildTrailerButton(isDesktop: isDesktop),
            ),
        ],
      ),
    );
  }

  Widget _buildMainDownloadButton({required bool isDesktop}) {
    return Obx(() {
      final bool userLoggedIn = authController.isLoggedIn.value;
      final bool isAlreadyDownloaded = downloadController.isDownloaded(
        content.id,
      );
      final bool downloading =
          downloadController.isDownloading[content.id] ?? false;
      final double progress =
          downloadController.downloadProgress[content.id] ?? 0;

      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 2),
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 22 : 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          if (!userLoggedIn) {
            Get.toNamed(
              AppRoutes.signIn,
              arguments: {"returnRoute": Get.currentRoute, "id": contentId},
            );
          } else if (isAlreadyDownloaded) {
            CustomSnackbar.show(title: "Info", message: "Already downloaded");
          } else {
            downloadController.downloadVideo(content);
          }
        },
        icon: downloading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                  value: progress > 0 ? progress : null,
                ),
              )
            : Icon(
                isAlreadyDownloaded
                    ? Icons.check_circle
                    : Icons.download_for_offline,
                color: Colors.white,
              ),
        label: Text(
          downloading
              ? "${(progress * 100).toInt()}%"
              : (isAlreadyDownloaded ? "DOWNLOADED" : "DOWNLOAD"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }

  Widget _buildWatchButton({required bool isDesktop}) {
    return Obx(() {
      final sub = premiumController.subscriptionData.value;
      final bool isPurchased = sub != null && sub['status'] == 'active';
      final bool userLoggedIn = authController.isLoggedIn.value;

      return GoldenButton(
        height: isDesktop ? 60 : 55,
        borderRadius: BorderRadius.circular(8),
        onPressed: content.isComingSoon
            ? null
            : () => _handlePlay(content, isPurchased, userLoggedIn),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: AppColors.buttonTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                content.isComingSoon ? "COMING SOON" : "WATCH NOW",
                style: const TextStyle(
                  color: AppColors.buttonTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _handlePlay(
    dynamic item,
    bool isPurchased,
    bool userLoggedIn, {
    bool? isPremiumOverride,
  }) async {
    final bool isPremium = isPremiumOverride ?? item.isPremium;
    if (!userLoggedIn) {
      Get.toNamed(AppRoutes.signIn);
    } else if (isPurchased || !isPremium) {
      if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
        if (item is ContentModel && item.is18Plus) {
          final bool? isOver18 = await Get.dialog<bool>(
            const AgeRestrictionPopup(),
          );
          if (isOver18 != true) return;
        }
        Get.toNamed(
          AppRoutes.videoPlayer,
          arguments: {'url': item.videoUrl!, 'title': item.title},
        );
      } else {
        CustomSnackbar.show(
          title: "Error",
          message: "Video URL not found",
          isError: true,
        );
      }
    } else {
      Get.toNamed(AppRoutes.goPremium);
    }
  }

  Widget _buildTrailerButton({required bool isDesktop}) {
    return GoldenButton(
      height: 40,
      width: 130,
      borderRadius: BorderRadius.circular(25),
      onPressed: () async {
        if (!authController.isLoggedIn.value) {
          Get.toNamed(
            AppRoutes.signIn,
            arguments: {"returnRoute": Get.currentRoute, "id": contentId},
          );
          return;
        }

        // 🔞 Agar content 18+ nahi hai to age dialog bilkul skip karo
        if (content.is18Plus != true) {
          print(content.trailerUrl);
          Get.toNamed(
            AppRoutes.videoPlayer,
            arguments: {
              'url': content.trailerUrl!,
              'title': '${content.title} - Trailer',
            },
          );
          return;
        }

        // 18+ content hai to age verification dialog dikhao
        final bool? isOver18 = await Get.dialog<bool>(
          const AgeRestrictionPopup(),
        );

        if (isOver18 == true) {
          print(content.trailerUrl);
          Get.toNamed(
            AppRoutes.videoPlayer,
            arguments: {
              'url': content.trailerUrl!,
              'title': '${content.title} - Trailer',
            },
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_outline,
            size: 18,
            color: AppColors.buttonTextColor,
          ),
          const SizedBox(width: 4),
          const Text(
            "TRAILER",
            style: TextStyle(
              color: AppColors.buttonTextColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionsRow() {
    return Obx(() {
      final String contentId = content.id;
      final bool userLoggedIn = authController.isLoggedIn.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleActionBtn(
            icon: watchlistController.isInWatchlist(contentId)
                ? Icons.check
                : Icons.add,
            label: "Watchlist",
            onTap: () {
              if (!userLoggedIn) {
                Get.toNamed(
                  AppRoutes.signIn,
                  arguments: {"returnRoute": Get.currentRoute, "id": contentId},
                );
              } else {
                watchlistController.toggleWatchlist(contentId);
              }
            },
          ),
          const SizedBox(width: 25),
          _circleActionBtn(
            icon: interactionController.isLiked(contentId)
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            label: "Like",
            onTap: () {
              if (!userLoggedIn) {
                Get.toNamed(
                  AppRoutes.signIn,
                  arguments: {"returnRoute": Get.currentRoute, "id": contentId},
                );
              } else {
                interactionController.toggleLike(
                  contentId: contentId,
                  contentType: content.contentType,
                );
              }
            },
          ),
          const SizedBox(width: 25),
          _circleActionBtn(
            icon: Icons.share_outlined,
            label: "Share",
            onTap: () {
              if (!userLoggedIn) {
                Get.toNamed(
                  AppRoutes.signIn,
                  arguments: {"returnRoute": Get.currentRoute, "id": contentId},
                );
              } else {
                ShareService.shareContent(
                  title: content.title,
                  imageUrl: content.poster,
                );
              }
            },
          ),
        ],
      );
    });
  }

  Widget _circleActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesSection(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Episodes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        /// SEASON SELECTOR (Modern Underline style)
        Row(
          children: List.generate(content.totalSeasons ?? 1, (index) {
            int seasonNum = index + 1;
            return Obx(() {
              bool isSelected = controller.selectedSeason.value == seasonNum;
              return GestureDetector(
                onTap: () => controller.selectedSeason.value = seasonNum,
                child: Container(
                  margin: const EdgeInsets.only(right: 30),
                  padding: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    "SEASON $seasonNum",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            });
          }),
        ),

        const SizedBox(height: 25),

        /// EPISODES LIST (Clean Rows)
        Obx(() {
          if (contentController.isEpisodesLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final episodes = contentController.seriesEpisodes
              .where(
                (item) => item.seasonNumber == controller.selectedSeason.value,
              )
              .toList();
          if (episodes.isEmpty) {
            return const Text(
              "Episodes are coming soon.",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white10, height: 20),
            itemBuilder: (context, index) =>
                _buildEpisodeRow(episodes[index], isDesktop),
          );
        }),
      ],
    );
  }

  Widget _buildEpisodeRow(ContentModel ep, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _playEpisode(ep),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// NUMBER
            SizedBox(
              width: 30,
              child: Text(
                "${ep.episodeNumber}",
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// THUMBNAIL
            Stack(
              alignment: Alignment.center,
              children: [
                CustomNetworkImage(
                  imageUrl: ep.poster,
                  width: isDesktop ? 200 : 120,
                  height: isDesktop ? 110 : 70,
                  fit: BoxFit.cover,
                  borderRadius: 8,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 15),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ep.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ep.duration ?? " ",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// DOWNLOAD BUTTON (More integrated & attractive)
            Obx(() {
              final bool downloading =
                  downloadController.isDownloading[ep.id] ?? false;
              final double progress =
                  downloadController.downloadProgress[ep.id] ?? 0;
              final bool isAlreadyDownloaded = downloadController.isDownloaded(
                ep.id,
              );

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _downloadEpisode(ep),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (downloading)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                                if (progress > 0)
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Icon(
                            isAlreadyDownloaded
                                ? Icons.check_circle
                                : Icons.download_for_offline_outlined,
                            color: isAlreadyDownloaded
                                ? Colors.green
                                : AppColors.primary,
                            size: 30,
                          ),
                        const SizedBox(height: 2),
                        GoldenText(
                          downloading
                              ? "WAIT"
                              : (isAlreadyDownloaded ? "SAVED" : "SAVE"),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCastSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cast & Crew",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: content.cast!.length,
            itemBuilder: (context, index) {
              final actor = content.cast![index];
              return GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.castDetails,
                  arguments: {'castName': actor.name, 'castImage': actor.image},
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 35),
                  child: Column(
                    children: [
                      ClipOval(
                        child: CustomNetworkImage(
                          imageUrl: actor.image,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        actor.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedSection(List<ContentModel> related, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "More Like This",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: isDesktop ? 300 : 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            itemBuilder: (context, index) {
              final item = related[index];
              return GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.dramaDetails,
                  arguments: {
                    'isSignedIn': authController.isLoggedIn.value,
                    'content': item,
                  },
                  preventDuplicates: false,
                ),
                child: Container(
                  width: isDesktop ? 200 : 135,
                  margin: const EdgeInsets.only(right: 20),
                  child: CustomNetworkImage(
                    imageUrl: item.poster,
                    fit: BoxFit.cover,
                    borderRadius: 8,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playEpisode(ContentModel episode) {
    final userLoggedIn = authController.isLoggedIn.value;
    final sub = premiumController.subscriptionData.value;
    final bool isPurchased = sub != null && sub['status'] == 'active';

    // An episode is considered premium if it is individually marked as premium
    // OR if the series it belongs to is marked as premium.
    final bool effectivePremium = episode.isPremium || widget.content.isPremium;

    _handlePlay(
      episode,
      isPurchased,
      userLoggedIn,
      isPremiumOverride: effectivePremium,
    );
  }

  void _downloadEpisode(ContentModel episode) {
    if (!authController.isLoggedIn.value) {
      Get.toNamed(
        AppRoutes.signIn,
        arguments: {"returnRoute": Get.currentRoute, "id": contentId},
      );
      return;
    }
    downloadController.downloadVideo(episode);
  }

  String _formatReleaseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Soon";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return "Soon";
    }
  }

  void _showSubscriptionDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
              const SizedBox(height: 20),
              const Text(
                "Subscription Required",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Unlock premium content and offline downloads with our subscription plans.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GoldenButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed(AppRoutes.goPremium);
                      },
                      child: const FittedBox(
                        child: Text(
                          "EXPLORE PLANS",
                          style: TextStyle(
                            color: AppColors.buttonTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
