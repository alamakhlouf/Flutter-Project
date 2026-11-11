import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub/core/utils/validators.dart';

void main() {
  test('full name is required', () {
    expect(Validators.fullName('  '), 'Enter your full name.');
    expect(Validators.fullName('Ada Lovelace'), isNull);
  });

  test('email must be present and shaped like an email', () {
    expect(Validators.email(''), 'Enter your email.');
    expect(Validators.email('not-an-email'), 'Enter a valid email address.');
    expect(Validators.email('person@example.com'), isNull);
  });

  test('password must contain at least 8 characters', () {
    expect(Validators.password(''), 'Enter a password.');
    expect(
      Validators.password('short'),
      'Password must be at least 8 characters.',
    );
    expect(Validators.password('password123'), isNull);
  });

  test('phone is optional and must look like a phone number', () {
    expect(Validators.phone(''), isNull);
    expect(Validators.phone('abc'), 'Enter a valid phone number.');
    expect(Validators.phone('123'), 'Enter a valid phone number.');
    expect(Validators.phone('+213 555 010 101'), isNull);
  });

  test('image link is optional and must be http or https', () {
    expect(Validators.imageUrl(''), isNull);
    expect(
      Validators.imageUrl('not a link'),
      'Enter an http or https image link.',
    );
    expect(Validators.imageUrl('https://example.com/photo.jpg'), isNull);
  });

  test('confirmation must match the password', () {
    expect(
      Validators.confirmPassword('', 'password123'),
      'Confirm your password.',
    );
    expect(
      Validators.confirmPassword('different', 'password123'),
      'Passwords do not match.',
    );
    expect(Validators.confirmPassword('password123', 'password123'), isNull);
  });
}
