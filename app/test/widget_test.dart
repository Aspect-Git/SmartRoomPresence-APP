import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_room_presence/login_screen.dart';
import 'package:smart_room_presence/main.dart';
import 'package:smart_room_presence/room_language.dart';

void main() {
  testWidgets('social login buttons are available as backend handoff points',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RoomApp());

    expect(find.byKey(const ValueKey('google-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('facebook-login')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('google-login')));
    await tester.tap(find.byKey(const ValueKey('google-login')));
    await tester.pump();
    expect(
        find.text(
            'Google sign-in is ready to connect when account services are set up.'),
        findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('social login callback identifies the selected provider',
      (tester) async {
    SocialLoginProvider? selectedProvider;
    await tester.pumpWidget(LanguageHost(
        child: MaterialApp(
            home: Scaffold(
                body: LoginScreen(
                    onEnter: (_) {},
                    onSocialLogin: (provider) =>
                        selectedProvider = provider)))));

    await tester.tap(find.byKey(const ValueKey('facebook-login')));
    expect(selectedProvider, SocialLoginProvider.google);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login validates, reveals password and signs out',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RoomApp());
    expect(find.text('Email address'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).first, 'alex@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'sample123');
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Meeting Room'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Email address'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Thai language works across tabs and logout retains selection',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RoomApp());
    await tester.tap(find.byKey(const ValueKey('language-switch')));
    await tester.pumpAndSettle();
    expect(find.text('อีเมล'), findsOneWidget);
    await tester.ensureVisible(find.text('ลองใช้งานเดโม'));
    await tester.tap(find.text('ลองใช้งานเดโม'));
    await tester.pumpAndSettle();
    expect(find.text('ห้องประชุม'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('ห้อง').last);
    await tester.pumpAndSettle();
    expect(find.text('อุปกรณ์ของฉัน'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('สถิติ').last);
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลการใช้งานห้อง'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('โปรไฟล์').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ออกจากระบบ'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(find.text('ออกจากระบบ')),
        alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกจากระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('อีเมล'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('language-switch')));
    await tester.tap(find.byKey(const ValueKey('language-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Email address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('notifications can be read individually and in bulk',
      (tester) async {
    await tester.pumpWidget(const RoomApp());
    await tester.ensureVisible(find.text('Explore demo'));
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('2 unread'), findsOneWidget);
    await tester.tap(find.text('Meeting Room A occupied · 42 min ago'));
    await tester.pumpAndSettle();
    expect(find.text('1 unread'), findsOneWidget);
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('All caught up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('navigation and room controls work at iPhone size',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RoomApp());
    await tester.ensureVisible(find.text('Explore demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    expect(find.text('Meeting Room'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Rooms'));
    await tester.pumpAndSettle();
    expect(find.text('My devices'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Open Smart light'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsWidgets);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Room insights'), findsOneWidget);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('4h 12m'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kanta');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Meeting Room'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small screen remains usable and presence changes',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RoomApp());
    await tester.ensureVisible(find.text('Explore demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Rooms'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Presence map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Person leaves'));
    await tester.pumpAndSettle();
    expect(find.text('1 people detected'), findsOneWidget);
    await tester.tap(find.text('Person leaves'));
    await tester.pumpAndSettle();
    expect(find.text('0 people detected'), findsOneWidget);
    await tester.tap(find.text('Set people count'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-1');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid whole number (0 or more)'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '125');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('125 people detected'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
