import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart'; // Adjust this import path if needed

class PhoneVerifyScreen extends ConsumerStatefulWidget {
  final String phone;

  const PhoneVerifyScreen({
    super.key,
    required this.phone,
  });

  @override
  ConsumerState<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends ConsumerState<PhoneVerifyScreen> {
  final otpController = TextEditingController();
  bool loading = false;
  String? errorMessage;

  Future<void> verifyPhone() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    bool isNavigating = false;

    try {
      // 1. Calls the backend communication method in the repository layer
      await ref.read(authRepositoryProvider).verifyPhone(
            token: otpController.text.trim(),
          );

      if (!mounted) return;

      // 2. Shows success notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone verified successfully"),
        ),
      );

      // 3. Flags that we are moving away to prevent local UI flashes
      isNavigating = true;
      context.go('/login');
    } catch (e) {
      print("VERIFY ERROR: $e");

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted && !isNavigating) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Phone"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Enter the verification code sent to ${widget.phone}",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "OTP Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : verifyPhone,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
