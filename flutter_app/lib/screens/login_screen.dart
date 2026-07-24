import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  bool _obscure    = true;

  late AnimationController _headerCtrl;
  late AnimationController _formCtrl;
  late Animation<double>   _logoScale;
  late Animation<double>   _headerFade;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _formCtrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _logoScale  = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.elasticOut));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);
    _formFade   = CurvedAnimation(parent: _formCtrl,   curve: Curves.easeOut);
    _formSlide  = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward().then((_) => _formCtrl.forward());
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _pwCtrl.dispose();
    _headerCtrl.dispose(); _formCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_emailCtrl.text.trim(), _pwCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      showSnack(context, auth.error ?? 'Login failed.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final size    = MediaQuery.of(context).size;

    return Scaffold(
      key: const Key('login_screen'),
      body: Stack(children: [
        Container(
          height: size.height * 0.42,
          decoration: const BoxDecoration(gradient: AppTheme.gradientPrimary),
          child: Stack(children: [
            Positioned(top: -50, right: -50,
                child: _circle(200, Colors.white.withOpacity(0.05))),
            Positioned(top: 100, left: -70,
                child: _circle(250, Colors.white.withOpacity(0.03))),
            FadeTransition(
              opacity: _headerFade,
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      key: const Key('login_logo'),
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety_rounded,
                          size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Periodontal Recall AI',
                      key: Key('login_app_title'),
                      style: TextStyle(fontSize: 24,
                          fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              )),
            ),
          ]),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _formSlide,
            child: FadeTransition(
              opacity: _formFade,
              child: Container(
                margin: EdgeInsets.only(top: size.height * 0.34),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Text('Welcome Back',
                            key: Key('login_welcome_text'),
                            style: TextStyle(fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 28),
                        // Email field
                        TextFormField(
                          key: const Key('login_email_field'),
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 14),
                        // Password field
                        TextFormField(
                          key: const Key('login_password_field'),
                          controller: _pwCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              key: const Key('login_toggle_password'),
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Too short' : null,
                        ),
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('login_forgot_password'),
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    const ForgotPasswordScreen())),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Sign In button
                        loading
                            ? const Center(
                                key: Key('login_loading'),
                                child: CircularProgressIndicator())
                            : ElevatedButton(
                                key: const Key('login_submit_button'),
                                onPressed: _login,
                                child: const Text('Sign In'),
                              ),
                        const SizedBox(height: 20),
                        // Register button
                        OutlinedButton(
                          key: const Key('login_register_button'),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Create New Account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
