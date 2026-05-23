import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

class PhoneVerifyScreen extends ConsumerStatefulWidget {
  final String token;

  const PhoneVerifyScreen({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends ConsumerState<PhoneVerifyScreen> {
  bool loading = true;
  String message = "";

  @override
  void initState() {
    super.initState();
    verify();
  }

  Future<void> verify() async {
    try {
      await ref.read(authRepositoryProvider).verifyPhone(widget.token);

      setState(() {
        message = "Phone verified successfully";
      });
    } catch (e) {
      setState(() {
        message = "Verification failed";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone Verification"),
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text(
                message,
                style: const TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
