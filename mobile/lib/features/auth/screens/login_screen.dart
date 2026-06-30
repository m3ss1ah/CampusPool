import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../../shared/widgets/cp_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted && ref.read(authNotifierProvider).value?.token != null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final auth = authAsync.value ?? const AuthState();

    return Scaffold(
      backgroundColor: AppColors.surface0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.spacing4xl),

                // Logo / Brand
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.signalYellow,
                    borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                  ),
                  child: const Icon(Icons.directions_bus, color: AppColors.systemBlack, size: 32),
                ),
                const SizedBox(height: AppConstants.spacing3xl),

                // Title
                const Text('LOG IN', style: AppTextStyles.displayLg),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'Access the CampusPool network.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppConstants.spacing3xl),

                // Error
                if (auth.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.rejectRed.withOpacity(0.1),
                      border: const Border(left: BorderSide(color: AppColors.rejectRed, width: 3)),
                    ),
                    child: Text(auth.error!, style: AppTextStyles.label.copyWith(color: AppColors.rejectRed)),
                  ),

                // Fields
                CpTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'student@university.edu',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v != null && v.contains('@') ? null : 'Valid email required',
                ),
                const SizedBox(height: AppConstants.spacingLg),
                CpTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textTertiary, size: 20,
                    ),
                  ),
                  validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                ),
                const SizedBox(height: AppConstants.spacing3xl),

                // Submit
                CpButton(
                  label: 'Log In',
                  icon: Icons.arrow_forward,
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppConstants.spacingXl),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New here? ', style: AppTextStyles.label),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'SIGN UP →',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.signalYellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
