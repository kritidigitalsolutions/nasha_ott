import 'package:get/get.dart';
import '../../view/auth/otpPage.dart';
import '../../view/auth/signInPage.dart';
import '../../view/homePages/mainHomepage.dart';
import '../../view/profile/create_ticket_page.dart';
import '../../view/profile/ticket_chat_page.dart';
import '../../view/profile/delete_account_page.dart';
import '../../view/splash/splashScreen.dart';
import '../../view/profile/privacy_policy_page.dart';
import '../../view/profile/terms_condition_page.dart';
import '../../view/profile/refund_policy_page.dart';
import '../../view/profile/help_page.dart';
import '../../view/profile/setting_page.dart';
import '../../view/profile/watchlist.dart';
import '../../view/navbar/downloads.dart';
import '../../view/search_pages/searchPage.dart';
import '../../view/premium/goPremium.dart';
import '../../view/premium/payment_success_page.dart';
import '../../view/notifications/notification_page.dart';
import '../../view/dramaDetails/dramaDetailsPage.dart';
import '../../view/videoPlayer/video_player.dart';
import '../../view/profile/purchased_plans_page.dart';
import '../../view/profile/Rate_your_app.dart';
import '../../view/dramaDetails/cast_crewPage.dart';
import '../../view/profile/create_profile_page.dart';
import '../../view/shorts/vertical_shorts_player.dart';
import '../../view/shorts/shorts_episodes_grid.dart';
import '../../view/popUp/redeem_voucher_page.dart';
import '../../widgets/catagory_widget.dart';
import '../../view/popUp/search_with_mic.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../data/models/shorts_model.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashScreen(),
      title: 'Splash | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => MainHomePage(),
      title: 'Home | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.upcoming,
      page: () => MainHomePage(),
      title: 'Upcoming | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.navbar,
      page: () => MainHomePage(),
      title: 'BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => MainHomePage(),
      title: 'Profile | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.createProfile,
      page: () => CreateProfilePage(
        phone: Get.arguments is Map ? Get.arguments['phone'] : null,
        id: Get.arguments is Map ? Get.arguments['id'] : null, // NEW
      ),
      title: 'Create Profile | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.signIn,
      page: () => SignInPage(),
      title: 'Sign In | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.otpPage,
      page: () => const OtpPage(),
      title: 'OTP Verification | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.createTicket,
      page: () => CreateTicketPage(),
      title: 'Create Ticket | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.ticketChat,
      page: () => TicketChatPage(ticket: Get.arguments),
      title: 'Ticket Chat | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.dramaDetails,
      page: () => DramaDetailsPage(
        isSignedIn: Get.arguments?['isSignedIn'] ?? false,
        content: Get.arguments?['content'] ?? ContentModel.fromJson({}),
        id: Get.arguments?['id'],
      ),
      title: 'Drama Details | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.goPremium,
      page: () => GoPremiumPage(),
      title: 'Go Premium | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.paymentSuccess,
      page: () => const PaymentSuccessPage(),
      title: 'Payment Success | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.watchList,
      page: () => WatchlistPage(),
      title: 'Watchlist | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.setting,
      page: () => SettingsPage(),
      title: 'Settings | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.downloads,
      page: () => DownloadsPage(),
      title: 'Downloads | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => SearchPage(),
      title: 'Search | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.searchWithMic,
      page: () => VoiceListeningPage(),
      title: 'Voice Search | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => NotificationPage(),
      title: 'Notifications | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => PrivacyPolicyPage(),
      title: 'Privacy Policy | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.termsAndConditions,
      page: () => TermsAndConditionsPage(),
      title: 'Terms & Conditions | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.refundPolicy,
      page: () => RefundPolicyPage(),
      title: 'Refund Policy | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.helpSupport,
      page: () => HelpSupportPage(),
      title: 'Help & Support | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.purchasedPlans,
      page: () => PurchasedPlansPage(),
      title: 'My Plans | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.rateApp,
      page: () => ReviewPage(),
      title: 'Rate App | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.videoPlayer,
      page: () => AdvancedVideoPlayer(
        url: Get.arguments?['url'] ?? '',
        title: Get.arguments?['title'] ?? 'Video Player',
      ),
      title: 'Watching | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.castDetails,
      page: () => CastDetailsPage(
        castName: Get.arguments?['castName'] ?? '',
        castImage: Get.arguments?['castImage'] ?? '',
      ),
      title: 'Cast Details | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.redeemVoucher,
      page: () => RedeemVoucherPage(),
      title: 'Redeem Voucher | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.shortsPlayer,
      page: () => VerticalShortsPlayer(
        episodes: Get.arguments?['episodes'] ?? [],
        initialIndex: Get.arguments?['initialIndex'] ?? 0,
        dramaName: Get.arguments?['dramaName'] ?? '',
      ),
      title: 'Shorts | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.shortsEpisodes,
      page: () => ShortsEpisodesGrid(
        drama: Get.arguments?['drama'] ?? ShortDrama.fromJson({}),
      ),
      title: 'Episodes | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.categoryGrid,
      page: () => CategoryGridPage(
        title: Get.arguments?['title'] ?? '',
        content: Get.arguments?['content'] ?? [],
        isSignedIn: Get.arguments?['isSignedIn'] ?? false,
      ),
      title: 'Category | BICHOO OTT',
    ),
    GetPage(
      name: AppRoutes.deleteAccount,
      page: () => const DeleteAccountPage(),
      title: 'Delete Account | BICHOO OTT',
    ),
  ];
}
