import 'package:flutter/material.dart';
import 'package:kimppakyyti/utilities/error.dart';
import 'package:kimppakyyti/widgets/loading_spinner.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      body: _isLoading
          ? const LoadingSpinner()
          : Center(
              child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await authProvider.signInWithGoogle();                      
                    } on SignInException catch (error) {
                      if (!context.mounted) return;
                      ErrorSnackbar.show(context, error);
                    } finally {
                      if (context.mounted) {
                        setState(() {
                        _isLoading = false;
                      });
                      }
                    }
                  },

                  // TODO: sign in assets
                  child: const Text("sign in")),
            ),
    );
  }
}
