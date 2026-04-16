import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneLogin = false;
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isPhoneLogin) ...[
                      _buildLabel('Email Address'),
                      _buildTextFormField(
                        controller: _emailController,
                        hint: 'alex@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Password'),
                      _buildTextFormField(
                        controller: _passwordController,
                        hint: 'Enter your password',
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
                      ),
                    ] else ...[
                      _buildLabel('Phone Number'),
                      _buildTextFormField(
                        controller: _phoneController,
                        hint: '03001234567',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your phone number';
                          if (!RegExp(r'^\d{10,15}$').hasMatch(value.replaceAll(RegExp(r'[\s\-\+]'), ''))) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isPhoneLogin = !_isPhoneLogin;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isPhoneLogin ? 'Use Email Instead' : 'Login with Phone',
                      style: const TextStyle(
                        color: Color(0xFFFF6600),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isPhoneLogin)
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFFF6600),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;

                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isLoading = true);
                    try {
                      if (!_isPhoneLogin) {
                        debugPrint('Attempting Email Login for: ${_emailController.text}');
                        await AuthService.signIn(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        
                        debugPrint('Sending Login OTP...');
                        await AuthService.sendOTP(_emailController.text.trim());
                      } else {
                        debugPrint('Attempting Phone Login for: ${_phoneController.text}');
                        await AuthService.sendPhoneOTP(_phoneController.text.trim());
                      }

                      // Set Pending state
                      await AuthService.setPendingOTP(true);
                      
                      if (!context.mounted) return;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OTPScreen(
                            email: _isPhoneLogin ? null : _emailController.text.trim(),
                            phone: _isPhoneLogin ? _phoneController.text.trim() : null,
                            type: _isPhoneLogin ? OtpType.sms : OtpType.email,
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Login Error Catch: $e');
                      String errorMessage = e.toString();

                      // Emergency Bypass for SMTP/Infrastructure Failures or Disabled Providers/Twilio Config Errors
                      if (errorMessage.contains('500') || 
                          errorMessage.contains('unexpected_failure') || 
                          errorMessage.contains('phone_provider_disabled') ||
                          errorMessage.contains('sms_send_failed') ||
                          errorMessage.contains('21212')) {
                        debugPrint('Infrastructure error or Provider config error, but continuing due to Bypass mode');
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OTPScreen(
                                email: _isPhoneLogin ? null : _emailController.text.trim(),
                                phone: _isPhoneLogin ? _phoneController.text.trim() : null,
                                type: _isPhoneLogin ? OtpType.sms : OtpType.email,
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      if (errorMessage.contains('Invalid login credentials')) {
                        errorMessage = 'Invalid email or password.';
                      }
                      
                      if (context.mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(errorMessage)),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFFF6600),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          errorStyle: const TextStyle(height: 0.8),
        ),
      ),
    );
  }
}
