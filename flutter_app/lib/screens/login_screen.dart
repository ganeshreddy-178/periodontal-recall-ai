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
      body: Stack(children: [
        // ── Gradient header ──
        Container(
          height: size.height * 0.42,
          decoration: const BoxDecoration(gradient: AppTheme.gradientPrimary),
          child: Stack(children: [
            // Decorative circles
            Positioned(top: -50, right: -50,
                child: _circle(200, Colors.white.withOpacity(0.05))),
            Positioned(top: 100, left: -70,
                child: _circle(250, Colors.white.withOpacity(0.03))),
            Positioned(bottom: 30, right: 40,
                child: _circle(80, Colors.white.withOpacity(0.06))),
            // Brand content
            FadeTransition(
              opacity: _headerFade,
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.health_and_safety_rounded,
                          size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Periodontal Recall AI',
                      style: TextStyle(fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Smart Dental Risk Prediction',
                        style: TextStyle(fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5)),
                  ),
                ],
              )),
            ),
          ]),
        ),

        // ── Form card ──
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
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32)),
                  boxShadow: [BoxShadow(
                    color: Color(0x1A1A237E),
                    blurRadius: 30, offset: Offset(0, -5),
                  )],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(child: Container(width: 40, height: 4,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8EAF6),
                                borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 24),

                        // Welcome text
                        const Text('Welcome Back',
                            style: TextStyle(fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('Sign in to your account',
                            style: TextStyle(fontSize: 14,
                                color: AppTheme.textMid)),
                        const SizedBox(height: 28),

                        // Email
                        _FormField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _FormField(
                          controller: _pwCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                                color: AppTheme.textMid, size: 20),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Too short' : null,
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    const ForgotPasswordScreen())),
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8)),
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Login button
                        loading
                            ? _GradientLoader()
                            : _GradientButton(
                                label: 'Sign In',
                                icon: Icons.login_rounded,
                                onTap: _login,
                              ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(children: [
                          const Expanded(child: Divider(
                              color: Color(0xFFE8EAF6))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 13)),
                          ),
                          const Expanded(child: Divider(
                              color: Color(0xFFE8EAF6))),
                        ]),
                        const SizedBox(height: 20),

                        // Register
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE8EAF6), width: 1.5),
                              boxShadow: [BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_outlined,
                                    color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text('Create New Account',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                          ),
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

// ── Shared form field ────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController  controller;
  final String                 label;
  final IconData               icon;
  final bool                   obscure;
  final Widget?                suffix;
  final TextInputType?         type;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure   = false,
    this.suffix,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.07),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      validator: validator,
      style: const TextStyle(
          fontWeight: FontWeight.w500, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        suffixIcon: suffix,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  const _GradientButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54, width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.42),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
    ),
  );
}

class _GradientLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 54, width: double.infinity,
    decoration: BoxDecoration(
      gradient: AppTheme.gradientPrimary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(child: SizedBox(width: 24, height: 24,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2.5))),
  );
}
