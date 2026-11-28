import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/core/constants/profile_options.dart';
import 'package:one_way_egypt/core/theme/oneway_theme.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_theme.dart';
import 'package:one_way_egypt/flutter_flow/nav/nav.dart';
import 'package:one_way_egypt/pages/authentication/authentication_widget.dart';
import 'package:one_way_egypt/pages/business_registration/business_registration_widget.dart';
import 'package:one_way_egypt/widgets/main_photo_picker_card.dart';

// Minimal valid 1x1 PNG for Image.memory tests.
final _samplePngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileOptions helpers', () {
    test('normalizes and validates Egyptian mobile numbers', () {
      expect(ProfileOptions.normalizeEgyptianPhone('+20 101-234-5678'),
          '01012345678');
      expect(ProfileOptions.normalizeEgyptianPhone('00201112345678'),
          '01112345678');
      expect(ProfileOptions.normalizeEgyptianPhone('201212345678'),
          '01212345678');
      expect(ProfileOptions.isValidEgyptianPhone('01512345678'), isTrue);
      expect(ProfileOptions.isValidEgyptianPhone('12345'), isFalse);
    });

    test('formats DateTime and Firestore Timestamp birth dates', () {
      final dt = DateTime(1998, 7, 15);
      expect(ProfileOptions.formatBirthDate(dt), '15/7/1998');
      expect(
        ProfileOptions.formatBirthDate(Timestamp.fromDate(dt)),
        '15/7/1998',
      );
      expect(ProfileOptions.governorates.length, 27);
    });
  });

  group('Registration personal profile fields', () {
    testWidgets(
        'toggling Create Account on AuthenticationWidget reveals all User Profile fields',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: AuthenticationWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch from login mode to registration mode
      final createBtn = find.text('إنشاء حساب جديد');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Verify all personal profile fields are rendered
      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_field')),
          findsOneWidget);
      expect(find.byKey(const Key('register_gender_field')), findsOneWidget);
      expect(find.byKey(const Key('register_birthdate_field')), findsOneWidget);
      expect(
          find.byKey(const Key('register_governorate_field')), findsOneWidget);
      expect(find.byKey(const Key('register_address_field')), findsOneWidget);
      expect(find.byKey(const Key('register_mobility_field')), findsOneWidget);
    });
  });

  group('Business Owner CTA routing & Main Photo Picker', () {
    testWidgets(
        'tapping "سجّل مكانك الآن" when signed out opens BusinessRegistrationWidget instead of bouncing back to login',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = AppStateNotifier.instance;
      final router = createRouter(notifier);
      router.goNamed(AuthenticationWidget.routeName);

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('ar'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
          routerConfig: router,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "سجّل مكانك الآن" on Login screen while NOT logged in
      final registerVenueBtn = find.text('سجّل مكانك الآن');
      await tester.ensureVisible(registerVenueBtn);
      await tester.pumpAndSettle();
      await tester.tap(registerVenueBtn);
      await tester.pumpAndSettle();

      // Must land on BusinessRegistrationWidget, NOT bounce back to AuthenticationWidget!
      expect(find.byType(BusinessRegistrationWidget), findsOneWidget);
      expect(
          find.byKey(const Key('business_reg_header_title')), findsOneWidget);
      expect(
          find.byKey(const Key('business_main_photo_picker')), findsOneWidget);

      // Fill Step 1 and advance to Step 2
      await tester.enterText(
        find.byKey(const Key('business_name_field')),
        'مستشفى الأمل',
      );
      await tester.enterText(
        find.byKey(const Key('business_phone_field')),
        '01012345678',
      );
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Step 2 displays Google Sign-In + inline owner account creation options when signed out
      expect(
        find.byKey(const Key('business_owner_google_signin_btn')),
        findsOneWidget,
      );
      expect(find.textContaining('المتابعة بحساب Google'), findsOneWidget);
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      expect(find.text('لدي حساب بالفعل'), findsOneWidget);
    });

    testWidgets('MainPhotoPickerCard handles pick, preview, and remove',
        (tester) async {
      var galleryTapped = false;
      var removed = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: MainPhotoPickerCard(
                  imageBytes: _samplePngBytes,
                  onPickGallery: () => galleryTapped = true,
                  onRemove: () => removed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الصورة الرئيسية للمكان'), findsOneWidget);
      expect(find.text('تغيير الصورة'), findsOneWidget);
      expect(find.text('حذف'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pick_main_photo_gallery_btn')));
      expect(galleryTapped, isTrue);

      await tester.tap(find.text('حذف'));
      expect(removed, isTrue);
    });
  });
}
