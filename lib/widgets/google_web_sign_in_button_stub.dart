import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({
    super.key,
    required this.googleSignIn,
    required this.onSignedIn,
  });

  final GoogleSignIn googleSignIn;
  final Future<void> Function(GoogleSignInAccount user) onSignedIn;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
