import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../../shared/widgets/cp_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    if (mounted && ref.read(authProvider).token != null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

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
                const SizedBox(height: AppConstants.spacing3xl),

                // Back
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('BACK', style: TextStyle(
                        fontFamily: 'SpaceMono', fontSize: 12,
                        color: AppColors.textSecondary, letterSpacing: 1.5,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacing3xl),

                Text('SIGN UP', style: AppTextStyles.displayLg),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'Join the CampusPool network.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppConstants.spacing3xl),

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

                CpTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Alex Rivera',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Name required',
                ),
                const SizedBox(height: AppConstants.spacingLg),
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

                CpButton(
                  label: 'Create Account',
                  icon: Icons.arrow_forward,
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
