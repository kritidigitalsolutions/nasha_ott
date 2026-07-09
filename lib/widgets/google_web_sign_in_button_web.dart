import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleWebSignInButton extends StatefulWidget {
  const GoogleWebSignInButton({
    super.key,
    required this.googleSignIn,
    required this.onSignedIn,
  });

  final GoogleSignIn googleSignIn;
  final Future<void> Function(GoogleSignInAccount user) onSignedIn;

  @override
  State<GoogleWebSignInButton> createState() => _GoogleWebSignInButtonState();
}

class _GoogleWebSignInButtonState extends State<GoogleWebSignInButton> {
  StreamSubscription<GoogleSignInAccount?>? _accountSubscription;
  bool _handlingSignIn = false;

  @override
  void initState() {
    super.initState();
    _accountSubscription = widget.googleSignIn.onCurrentUserChanged.listen(
      _handleAccount,
    );
  }

  Future<void> _handleAccount(GoogleSignInAccount? account) async {
    if (account == null || _handlingSignIn) {
      return;
    }

    _handlingSignIn = true;
    try {
      await widget.onSignedIn(account);
    } finally {
      _handlingSignIn = false;
    }
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Center(
        child: web.renderButton(
          configuration: web.GSIButtonConfiguration(
            type: web.GSIButtonType.standard,
            theme: web.GSIButtonTheme.filledBlack,
            size: web.GSIButtonSize.large,
            text: web.GSIButtonText.continueWith,
            shape: web.GSIButtonShape.rectangular,
            logoAlignment: web.GSIButtonLogoAlignment.left,
            minimumWidth: 400,
          ),
        ),
      ),
    );
  }
}
