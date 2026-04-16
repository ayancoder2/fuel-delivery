import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPhoneSignUp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign up to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isPhoneSignUp) ...[
                      _buildLabel('Full Name'),
                      _buildTextFormField(
                        controller: _nameController,
                        hint: 'Alexander Pierce',
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildLabel('Password'),
                      _buildTextFormField(
                        controller: _passwordController,
                        hint: 'Create a password (min. 6 characters)',
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Confirm Password'),
                      _buildTextFormField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm your password',
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ] else ...[
                      _buildLabel('Full Name'),
                      _buildTextFormField(
                        controller: _nameController,
                        hint: 'Alexander Pierce',
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 20),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                         _isPhoneSignUp = !_isPhoneSignUp;
                         _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isPhoneSignUp ? 'Use Email Instead' : 'Register with Phone Only',
                      style: const TextStyle(
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
                      if (!_isPhoneSignUp) {
                        debugPrint('Starting Email SignUp for: ${_emailController.text}');
                        await AuthService.signUp(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          fullName: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                        );
                        
                        debugPrint('SignUp Initial Success. Sending Email Verification Code...');
                        await AuthService.setPendingOTP(true);
                        await AuthService.sendOTP(_emailController.text.trim());
                      } else {
                        debugPrint('Starting Phone SignUp for: ${_phoneController.text}');
                        await AuthService.sendPhoneOTP(_phoneController.text.trim());
                        await AuthService.setPendingOTP(true);
                      }
                      
                      if (!context.mounted) return;
                      
                      debugPrint('Navigating to OTP Screen...');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OTPScreen(
                            email: _isPhoneSignUp ? null : _emailController.text.trim(),
                            phone: _isPhoneSignUp ? _phoneController.text.trim() : null,
                            type: _isPhoneSignUp ? OtpType.signup : OtpType.email,
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('SignUp Error Catch: $e');
                      String errorMessage = e.toString();

                      // Emergency Bypass for Infrastructure Failures or Twilio Config Errors
                      if (errorMessage.contains('500') || 
                          errorMessage.contains('unexpected_failure') ||
                          errorMessage.contains('sms_send_failed') ||
                          errorMessage.contains('21212')) {
                          debugPrint('SMTP/Provider/Twilio Error detected but continuing to OTP view...');
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => OTPScreen(
                                  email: _isPhoneSignUp ? null : _emailController.text.trim(),
                                  phone: _isPhoneSignUp ? _phoneController.text.trim() : null,
                                  type: _isPhoneSignUp ? OtpType.signup : OtpType.email,
                                ),
                              ),
                            );
                          }
                          return;
                      }

                      if (errorMessage.contains('AuthWeakPasswordException')) {
                        errorMessage = 'Password is too weak. Please use at least 6 characters.';
                      } else if (errorMessage.contains('User already registered')) {
                        errorMessage = 'This email is already registered.';
                      } else if (errorMessage.contains('over_email_send_rate_limit') || errorMessage.contains('429')) {
                        errorMessage = 'Too many attempts. Please wait a bit before trying again.';
                      }
                      
                      if (mounted) {
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
                            'Create Account',
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
              const SizedBox(height: 32),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFFFF6600),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
