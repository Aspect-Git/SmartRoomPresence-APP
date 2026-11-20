import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../room_language.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/room_theme.dart';

enum SocialLoginProvider { google }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onEnter,
    this.onSocialLogin,
  });

  final ValueChanged<String?> onEnter;
  final ValueChanged<SocialLoginProvider>? onSocialLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _visible = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveUser(
    User user, {
    bool isNew = false,
  }) async {
    final name = user.displayName ?? user.email?.split('@').first ?? 'User';

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': name,
      'photoURL': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    _password.clear();
    TextInput.finishAutofillContext(shouldSave: true);
    widget.onEnter(name);
  }

  // Email and password login
  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      await _saveUser(result.user!);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? e.code);
    } catch (e) {
      _message('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Create a new account
  Future<void> _register() async {
    if (_busy || !_form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final user = result.user!;
      final name = user.email!.split('@').first;

      await user.updateDisplayName(name);

      await _saveUser(user, isNew: true);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? e.code);
    } catch (e) {
      _message('Registration error: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Forgot password
  Future<void> _help() async {
    if (_busy) return;

    final email = _email.text.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _message('Please enter a valid email address.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _message(
        'If your account exists, a password reset email will be sent.',
      );
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? e.code);
    } catch (e) {
      _message('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Google login for web
  Future<void> _startSocialLogin(
    SocialLoginProvider provider,
  ) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final result =
          await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());

      await _saveUser(result.user!);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? e.code);
    } catch (e) {
      _message('Google sign-in: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(RoomShape.control),
                          child: Image.asset(
                            'assets/brand/room-app-icon.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            semanticLabel: 'Smart Room app logo',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RoomText('Smart Room',
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: RoomColors.ink)),
                              RoomText('Presence & room conditions',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: RoomColors.secondary)),
                            ],
                          ),
                        ),
                        const LanguagePicker(compact: true),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: RoomColors.raised,
                        borderRadius: BorderRadius.circular(RoomShape.panel),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Room conditions, clearly measured',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.ink)),
                          SizedBox(height: 8),
                          Text(
                              'Presence · CO₂ · temperature · humidity · light',
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: RoomColors.secondary)),
                          SizedBox(height: 14),
                          Row(children: [
                            Icon(Icons.shield_outlined,
                                size: 16, color: RoomColors.coralInk),
                            SizedBox(width: 7),
                            Expanded(
                                child: Text('Radar sensing, without a camera',
                                    style: TextStyle(
                                        fontSize: 12, color: RoomColors.ink))),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    AutofillGroup(
                      child: Column(
                        children: [
                          // Email input
                          TextFormField(
                            key: const ValueKey('email-field'),
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: tr(context, 'Email address'),
                              hintText: 'you@example.com',
                              prefixIcon: const Icon(
                                Icons.alternate_email,
                              ),
                            ),
                            validator: (value) => value != null &&
                                    RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    ).hasMatch(value.trim())
                                ? null
                                : tr(
                                    context,
                                    'Enter a valid email address',
                                  ),
                          ),

                          const SizedBox(height: 14),

                          // Password input
                          TextFormField(
                            key: const ValueKey('password-field'),
                            controller: _password,
                            enabled: !_busy,
                            obscureText: !_visible,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: tr(context, 'Password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                          () => _visible = !_visible,
                                        ),
                                tooltip: _visible
                                    ? tr(context, 'Hide password')
                                    : tr(context, 'Show password'),
                                icon: Icon(
                                  _visible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) >= 6
                                ? null
                                : tr(
                                    context,
                                    'Use at least 6 characters',
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Forgot password button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _help,
                        child: const RoomText(
                          'Forgot password?',
                        ),
                      ),
                    ),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: RoomColors.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(
                            context,
                          )
                              ? Duration.zero
                              : const Duration(
                                  milliseconds: 150,
                                ),
                          child: _busy
                              ? const SizedBox(
                                  key: ValueKey('busy'),
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  key: ValueKey('sign-in'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RoomText('Sign in'),
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Create account button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _register,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RoomColors.coralInk,
                          side: const BorderSide(
                            color: RoomColors.coralInk,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const RoomText(
                          'Create account',
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: RoomText(
                              'Or continue with',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Google login button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey('google-login'),
                        onPressed: _busy
                            ? null
                            : () => _startSocialLogin(
                                  SocialLoginProvider.google,
                                ),
                        icon: const _GoogleMark(),
                        label: const RoomText('Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RoomColors.ink,
                          side: const BorderSide(
                            color: Color(0xFFD8D5CF),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Demo mode
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => widget.onEnter(null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RoomColors.ink,
                          side: const BorderSide(
                            color: Color(0xFFD8D5CF),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const RoomText('Explore demo'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Center(
                      child: RoomText(
                        'Secure sign-in with Firebase',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
        'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      );
}
