/// Shared validation for the Supabase email/password sign-in form.
bool isValidLoginEmail(String value) {
  final email = value.trim();
  return RegExp(r'^[^@\s]+@[^@\s.]+(?:\.[^@\s.]+)+$').hasMatch(email);
}

String? loginValidationMessage({required String email, required String password}) {
  if (email.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
  if (!isValidLoginEmail(email)) return 'صيغة البريد الإلكتروني غير صحيحة';
  if (password.isEmpty) return 'يرجى إدخال كلمة المرور';
  return null;
}
