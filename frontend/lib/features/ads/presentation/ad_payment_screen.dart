import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ad_dtos.dart';
import '../data/ad_repository.dart';

/// Opened from the email link after moderator approval: /advertise/pay/:id
class AdPaymentScreen extends ConsumerStatefulWidget {
  final int adId;
  const AdPaymentScreen({super.key, required this.adId});

  @override
  ConsumerState<AdPaymentScreen> createState() => _AdPaymentScreenState();
}

class _AdPaymentScreenState extends ConsumerState<AdPaymentScreen> {
  final _txnCtl = TextEditingController();
  PaymentMethod _method = PaymentMethod.telebirr;
  bool _loading = true;
  String? _error;
  Advertisement? _ad;
  double _amountDue = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _txnCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(adRepositoryProvider).getForPayment(widget.adId);
      setState(() {
        _ad = result.advertisement;
        _amountDue = result.amountEtb;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitPayment() async {
    if (_txnCtl.text.trim().length < 4) {
      setState(() => _error = 'Enter your payment transaction ID');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(adRepositoryProvider).submitPayment(
            adId: widget.adId,
            method: _method,
            transactionId: _txnCtl.text.trim(),
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment complete'),
          content: const Text(
            'Your advertisement is now live on the platform for the period you selected.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/landing');
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ad = _ad;

    return ResponsiveShell(
      title: 'Complete payment',
      child: _loading && ad == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && ad == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/landing'),
                      child: const Text('Back to home'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ad != null) ...[
                      Text(ad.title, style: theme.textTheme.headlineSmall),
                      Text(
                          '${ad.companyName} · ${ad.placementType.label()} · ${ad.durationDays} days'),
                      const SizedBox(height: 8),
                      Text(
                        'Amount due: ${_amountDue.toStringAsFixed(0)} ETB',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pay using Telebirr, CBE Birr, or bank transfer, then enter your transaction reference below.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!,
                            style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    DropdownButtonFormField<PaymentMethod>(
                      value: _method,
                      decoration:
                          const InputDecoration(labelText: 'Payment method'),
                      items: PaymentMethod.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.label()),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _method = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _txnCtl,
                      decoration: const InputDecoration(
                        labelText: 'Transaction ID / reference',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submitPayment,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit payment & go live'),
                    ),
                  ],
                ),
    );
  }
}
