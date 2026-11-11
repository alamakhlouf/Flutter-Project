class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your full name.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email.';
    if (!_email.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[0-9+().\-\s]+$').hasMatch(text)) {
      return 'Enter a valid phone number.';
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? imageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final supported =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!supported) return 'Enter an http or https image link.';
    return null;
  }
}
