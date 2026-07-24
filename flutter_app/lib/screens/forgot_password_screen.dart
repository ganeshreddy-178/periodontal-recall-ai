import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // Steps: 0 = enter email, 1 = enter OTP, 2 = new password, 3 = success
  int _step = 0;

  final _emailCtrl    = TextEditingController();
  final _otpCtrls     = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes= List.generate(6, (_) => FocusNode());
  final _pwCtrl       = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool    _loading     = false;
  bool    _obscurePw   = true;
  bool    _obscureConf = true;
  String  _resetToken  = '';
  int     _resendTimer = 0;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  void _nextStep() {
    _animCtrl.reset();
    setState(() => _step++);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Request OTP ─────────────────────────────────────────────
  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showSnack(context, 'Enter a valid email address.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.requestOtp(email);
      if (!mounted) return;
      if (res['success'] == true) {
        showSnack(context, res['message'] as String);
        _nextStep();
        _startResendTimer();
      } else {
        showSnack(context, res['message'] as String? ?? 'Error', error: true);
      }
    } catch (_) {
      showSnack(context, 'Network error.', error: true);
    }
    setState(() => _loading = false);
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length != 6) {
      showSnack(context, 'Enter the 6-digit OTP.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.verifyOtp(
          _emailCtrl.text.trim(), otp);
      if (!mounted) return;
      if (res['success'] == true) {
        _resetToken = (res['data']?['reset_token'] as String?) ?? '';
        showSnack(context, 'OTP verified!');
        _nextStep();
      } else {
        showSnack(context, res['message'] as String? ?? 'Invalid OTP',
            error: true);
      }
    } catch (_) {
      showSnack(context, 'Network error.', error: true);
    }
    setState(() => _loading = false);
  }

  // ── Step 3: Reset Password ──────────────────────────────────────────
  Future<void> _resetPassword() async {
    final pw   = _pwCtrl.text;
    final conf = _confirmCtrl.text;
    if (pw.length < 8) {
      showSnack(context, 'Password must be at least 8 characters.', error: true);
      return;
    }
    if (pw != conf) {
      showSnack(context, 'Passwords do not match.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.resetPassword(
          _emailCtrl.text.trim(), _resetToken, pw);
      if (!mounted) return;
      if (res['success'] == true) {
        _nextStep(); // success screen
      } else {
        showSnack(context, res['message'] as String? ?? 'Error', error: true);
      }
    } catch (_) {
      showSnack(context, 'Network error.', error: true);
    }
    setState(() => _loading = false);
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendTimer--);
      return _resendTimer > 0;
    });
  }

  // ── OTP input handler ───────────────────────────────────────────────
  void _onOtpChanged(String val, int index) {
    if (val.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (val.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('forgot_password_screen'),
      backgroundColor: AppTheme.surface,
        // Gradient header
        Container(
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: const BoxDecoration(gradient: AppTheme.gradientPrimary),
          child: Stack(children: [
            Positioned(top: -40, right: -40,
                child: _circle(180, Colors.white.withOpacity(0.06))),
            Positioned(top: 80, left: -60,
                child: _circle(160, Colors.white.withOpacity(0.04))),
            SafeArea(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => _step > 0 && _step < 3
                      ? setState(() => _step--)
                      : Navigator.pop(context),
                ),
              ]),
            )),
            Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_stepIcon(), size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(_stepTitle(),
                    style: const TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(_stepSubtitle(),
                    style: TextStyle(fontSize: 13,
                        color: Colors.white.withOpacity(0.75))),
              ],
            )),
          ]),
        ),

        // Step indicator dots
        Positioned(
          top: MediaQuery.of(context).size.height * 0.30,
          left: 0, right: 0,
          child: Center(child: _StepDots(current: _step > 2 ? 2 : _step)),
        ),

        // Content card
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildEmailStep();
      case 1: return _buildOtpStep();
      case 2: return _buildPasswordStep();
      default: return _buildSuccessStep();
    }
  }

  // ── Email step ──────────────────────────────────────────────────────
  Widget _buildEmailStep() => Column(children: [
    _GlassInput(
      controller: _emailCtrl,
      label: 'Registered Email',
      icon: Icons.email_outlined,
      type: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accent),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'A 6-digit OTP will be sent to your registered email.',
          style: TextStyle(fontSize: 12, color: AppTheme.accent),
        )),
      ]),
    ),
    const SizedBox(height: 28),
    _loading
        ? const _LoadBtn()
        : _GradBtn(label: 'Send OTP', icon: Icons.send_rounded,
            onTap: _requestOtp),
  ]);

  // ── OTP step ────────────────────────────────────────────────────────
  Widget _buildOtpStep() => Column(children: [
    Text('Enter the 6-digit code sent to',
        style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
    const SizedBox(height: 4),
    Text(_emailCtrl.text.trim(),
        style: const TextStyle(color: AppTheme.primary,
            fontWeight: FontWeight.w700, fontSize: 14)),
    const SizedBox(height: 28),
    // OTP boxes
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) => _OtpBox(
          controller: _otpCtrls[i],
          focusNode: _otpFocusNodes[i],
          onChanged: (v) => _onOtpChanged(v, i),
        ))),
    const SizedBox(height: 24),
    // Resend
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Didn\'t receive it? ',
          style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
      _resendTimer > 0
          ? Text('Resend in ${_resendTimer}s',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13))
          : GestureDetector(
              onTap: () { _requestOtp(); },
              child: Text('Resend OTP',
                  style: TextStyle(color: AppTheme.primary,
                      fontWeight: FontWeight.w700, fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primary)),
            ),
    ]),
    const SizedBox(height: 28),
    _loading
        ? const _LoadBtn()
        : _GradBtn(label: 'Verify OTP', icon: Icons.verified_rounded,
            onTap: _verifyOtp),
  ]);

  // ── New password step ───────────────────────────────────────────────
  Widget _buildPasswordStep() => Column(children: [
    _GlassInput(
      controller: _pwCtrl,
      label: 'New Password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscurePw,
      suffix: IconButton(
        icon: Icon(_obscurePw ? Icons.visibility_off_outlined
            : Icons.visibility_outlined, color: AppTheme.textMid),
        onPressed: () => setState(() => _obscurePw = !_obscurePw),
      ),
    ),
    const SizedBox(height: 14),
    _GlassInput(
      controller: _confirmCtrl,
      label: 'Confirm Password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscureConf,
      suffix: IconButton(
        icon: Icon(_obscureConf ? Icons.visibility_off_outlined
            : Icons.visibility_outlined, color: AppTheme.textMid),
        onPressed: () => setState(() => _obscureConf = !_obscureConf),
      ),
    ),
    const SizedBox(height: 12),
    // Password rules
    _PasswordRule(label: 'At least 8 characters',
        met: _pwCtrl.text.length >= 8),
    _PasswordRule(label: 'Contains a letter',
        met: RegExp(r'[A-Za-z]').hasMatch(_pwCtrl.text)),
    _PasswordRule(label: 'Contains a number',
        met: RegExp(r'\d').hasMatch(_pwCtrl.text)),
    const SizedBox(height: 20),
    _loading
        ? const _LoadBtn()
        : _GradBtn(label: 'Reset Password', icon: Icons.check_circle_rounded,
            onTap: _resetPassword),
  ]);

  // ── Success step ────────────────────────────────────────────────────
  Widget _buildSuccessStep() => Column(children: [
    const SizedBox(height: 20),
    Center(child: Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        gradient: AppTheme.gradientSuccess,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
            color: AppTheme.riskLow.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
    )),
    const SizedBox(height: 24),
    const Text('Password Reset!',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
            color: AppTheme.textDark)),
    const SizedBox(height: 8),
    Text('Your password has been reset successfully.\nYou can now login with your new password.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textMid, fontSize: 14, height: 1.6)),
    const SizedBox(height: 36),
    _GradBtn(
      label: 'Back to Login',
      icon: Icons.login_rounded,
      onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false),
    ),
  ]);

  // ── Helpers ─────────────────────────────────────────────────────────
  IconData _stepIcon() {
    switch (_step) {
      case 0: return Icons.email_outlined;
      case 1: return Icons.pin_outlined;
      case 2: return Icons.lock_reset_rounded;
      default: return Icons.check_circle_outline_rounded;
    }
  }

  String _stepTitle() {
    switch (_step) {
      case 0: return 'Forgot Password?';
      case 1: return 'Verify OTP';
      case 2: return 'New Password';
      default: return 'All Done!';
    }
  }

  String _stepSubtitle() {
    switch (_step) {
      case 0: return 'Enter your email to receive an OTP';
      case 1: return 'Check your inbox for the 6-digit code';
      case 2: return 'Set a strong new password';
      default: return 'Your password has been updated';
    }
  }

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Sub-widgets ──────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int current;
  const _StepDots({required this.current});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width:  i == current ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: i == current ? AppTheme.primary
            : i < current  ? AppTheme.accent
            : const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(4),
      ),
    )),
  );
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({required this.controller, required this.focusNode,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    width: 46, height: 56,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.08),
          blurRadius: 8, offset: const Offset(0, 3))],
      border: Border.all(color: const Color(0xFFE8EAF6), width: 1.5),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
          color: AppTheme.primary),
      decoration: const InputDecoration(
        counterText: '',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? type;
  const _GlassInput({required this.controller, required this.label,
      required this.icon, this.obscure = false, this.suffix, this.type});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.07),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      onChanged: (_) {},
      style: const TextStyle(fontWeight: FontWeight.w500,
          color: AppTheme.textDark),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    ),
  );
}

class _PasswordRule extends StatelessWidget {
  final String label;
  final bool   met;
  const _PasswordRule({required this.label, required this.met});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 18, height: 18,
        decoration: BoxDecoration(
          color: met ? AppTheme.riskLow : const Color(0xFFEEF0FA),
          shape: BoxShape.circle,
        ),
        child: Icon(met ? Icons.check_rounded : Icons.remove_rounded,
            size: 12, color: met ? Colors.white : AppTheme.textLight),
      ),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          fontSize: 12,
          color: met ? AppTheme.riskLow : AppTheme.textLight)),
    ]),
  );
}

class _GradBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54, width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
    ),
  );
}

class _LoadBtn extends StatelessWidget {
  const _LoadBtn();
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
