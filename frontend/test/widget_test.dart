import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/auth/data/auth_dtos.dart';

void main() {
  group('UserRoleX wire mapping', () {
    test('round-trips every enum value', () {
      for (final r in UserRole.values) {
        expect(UserRoleX.fromWire(r.toWire()), r);
      }
    });

    test('matches backend Zod-accepted strings exactly', () {
      expect(UserRole.parent.toWire(), 'PARENT');
      expect(UserRole.schoolAdmin.toWire(), 'SCHOOL_ADMIN');
      expect(UserRole.moeOfficer.toWire(), 'MOE_OFFICER');
      expect(UserRole.moderator.toWire(), 'MODERATOR');
    });

    test('throws on unknown wire string', () {
      expect(() => UserRoleX.fromWire('SOMETHING_ELSE'), throwsArgumentError);
    });
  });

  group('AppUser.fromJson', () {
    test('parses a full payload', () {
      final user = AppUser.fromJson({
        'id': 7,
        'fullName': 'Test User',
        'email': 'test@example.com',
        'phone': '0911000000',
        'role': 'PARENT',
        'emailVerified': true,
        'accountStatus': 'ACTIVE',
      });
      expect(user.id, 7);
      expect(user.fullName, 'Test User');
      expect(user.role, UserRole.parent);
      expect(user.emailVerified, true);
    });

    test('tolerates missing optional fields', () {
      final user = AppUser.fromJson({
        'id': 7,
        'fullName': 'Test User',
        'email': 'test@example.com',
        'phone': null,
        'role': 'SCHOOL_ADMIN',
      });
      expect(user.phone, isNull);
      expect(user.emailVerified, false);
      expect(user.accountStatus, 'ACTIVE');
    });
  });
}
