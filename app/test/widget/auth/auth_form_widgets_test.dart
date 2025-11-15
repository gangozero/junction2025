/// Widget tests for auth form widgets
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/auth/presentation/widgets/email_field.dart';
import 'package:harvia_msga/features/auth/presentation/widgets/password_field.dart';
import 'package:harvia_msga/features/auth/presentation/widgets/login_button.dart';

void main() {
  group('EmailField Widget Tests', () {
    testWidgets('should display email text field', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmailField(controller: controller)),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('should accept valid email input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmailField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pumpAndSettle();

      expect(controller.text, 'test@example.com');
    });

    testWidgets('should show email icon', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmailField(controller: controller)),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('should have email keyboard type', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmailField(controller: controller)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });
  });

  group('PasswordField Widget Tests', () {
    testWidgets('should display password text field', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordField(controller: controller)),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should obscure password by default', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordField(controller: controller)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('should toggle password visibility', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordField(controller: controller)),
        ),
      );

      // Initial state - password obscured
      TextField textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      // Tap visibility icon
      final visibilityButton = find.byType(IconButton);
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Password should now be visible
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
    });

    testWidgets('should accept password input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'password123');
      await tester.pumpAndSettle();

      expect(controller.text, 'password123');
    });
  });

  group('LoginButton Widget Tests', () {
    testWidgets('should display login button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoginButton(onPressed: () {}, isLoading: false)),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginButton(
              onPressed: () => pressed = true,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('should show loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoginButton(onPressed: () {}, isLoading: true)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('should be disabled when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoginButton(onPressed: () {}, isLoading: true)),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should be enabled when isLoading is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoginButton(onPressed: () {}, isLoading: false)),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
