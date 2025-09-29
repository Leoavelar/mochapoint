// lib/widgets/redemption_selection_modal.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/redemption_service.dart';
import '../config/app_config.dart';

class RedemptionSelectionModal extends StatefulWidget {
  final String? initialRedemptionType; // 'subscription' or 'joker' or null for selection

  const RedemptionSelectionModal({
    Key? key,
    this.initialRedemptionType,
  }) : super(key: key);

  @override
  State<RedemptionSelectionModal> createState() => _RedemptionSelectionModalState();
}

class _RedemptionSelectionModalState extends State<RedemptionSelectionModal> {
  Map<String, dynamic>? _redemptionStatus;
  String? _selectedRedemptionType;
  String? _qrToken;
  bool _isLoading = false;
  String? _error;
  bool _isGeneratingQR = false;

  @override
  void initState() {
    super.initState();
    _loadRedemptionStatus();
  }

  Future<void> _loadRedemptionStatus() async {
    if (AppConfig.enableLogging) {
      print('🔍 RedemptionModal: Loading redemption status');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await RedemptionService.getRedemptionStatus();

      if (result['success']) {
        setState(() {
          _redemptionStatus = result['status'];
          _isLoading = false;
        });

        // If initial redemption type is provided, generate QR immediately
        if (widget.initialRedemptionType != null && mounted) {
          _generateQRCode(widget.initialRedemptionType!);
        }
      } else {
        if (AppConfig.enableLogging) {
          print('❌ RedemptionModal: Failed to load status');
        }

        // Check if this is a session expiry
        if (result['isSessionExpired'] == true ||
            result['errorCode'] == 'SESSION_EXPIRED' ||
            result['errorCode'] == 'TOKEN_EXPIRED') {
          Navigator.of(context).pop();
          _showSessionExpiredDialog();
          return;
        }

        setState(() {
          _error = result['error'] ?? 'Unknown error from server';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ RedemptionModal: Exception: $e');
      }
      setState(() {
        _error = 'Failed to get redemption status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateQRCode(String redemptionType) async {
    if (AppConfig.enableLogging) {
      print('🎫 RedemptionModal: Generating QR for $redemptionType');
    }

    setState(() {
      _isGeneratingQR = true;
      _error = null;
    });

    try {
      final result = await RedemptionService.generateQRToken(redemptionType);

      if (result['success']) {
        setState(() {
          _selectedRedemptionType = redemptionType;
          _qrToken = result['qrToken'];
          _isGeneratingQR = false;
        });
      } else {
        if (AppConfig.enableLogging) {
          print('❌ RedemptionModal: QR generation failed');
        }

        // Check if this is a session expiry
        if (result['isSessionExpired'] == true ||
            result['errorCode'] == 'SESSION_EXPIRED' ||
            result['errorCode'] == 'TOKEN_EXPIRED') {
          Navigator.of(context).pop();
          _showSessionExpiredDialog();
          return;
        }

        setState(() {
          _error = result['error'] ?? 'Unknown QR generation error';
          _isGeneratingQR = false;
        });

        // If there's a next available time, show it
        if (result['nextAvailableAt'] != null) {
          final timeUntilNext = RedemptionService.getTimeUntilNextRedemption(result['nextAvailableAt']);
          setState(() {
            _error = '${result['error']}\n$timeUntilNext';
          });
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ RedemptionModal: QR exception: $e');
      }
      setState(() {
        _error = 'Failed to generate QR code: $e';
        _isGeneratingQR = false;
      });
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Session Expired',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        content: const Text(
          'Your session has expired for security reasons. Please log in again to continue.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                    (route) => false,
              );
            },
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _qrToken == null) {
      return _buildErrorState();
    }

    if (_qrToken != null) {
      return _buildQRCodeView();
    }

    return _buildRedemptionSelection();
  }

  Widget _buildErrorState() {
    final isSessionError = _error!.contains('session') ||
        _error!.contains('expired') ||
        _error!.contains('log in');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSessionError ? Icons.lock_clock_outlined : Icons.error_outline,
            size: 64,
            color: isSessionError ? Colors.orange[300] : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            isSessionError ? 'Session Expired' : 'Unable to Generate QR Code',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isSessionError)
                ElevatedButton(
                  onPressed: _loadRedemptionStatus,
                  child: const Text('Try Again'),
                ),
              if (isSessionError)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                          (route) => false,
                    );
                  },
                  child: const Text('Login Again'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionSelection() {
    final status = _redemptionStatus;
    if (status == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Choose Redemption Type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how you\'d like to redeem your coffee',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          _buildRedemptionOption(
            type: 'subscription',
            title: 'Subscription Coffee',
            subtitle: _getSubscriptionSubtitle(status),
            icon: Icons.coffee,
            enabled: status['canRedeemSubscription'] ?? false,
            available: _getSubscriptionAvailable(status),
          ),

          const SizedBox(height: 16),

          _buildRedemptionOption(
            type: 'joker',
            title: 'Use Joker',
            subtitle: 'Valid at any participating coffee shop',
            icon: Icons.stars,
            enabled: status['canRedeemJoker'] ?? false,
            available: '${status['jokerCount'] ?? 0} jokers available',
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required String available,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: enabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? () => _generateQRCode(type) : null,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enabled ? Theme.of(context).primaryColor : Colors.grey[300]!,
                width: enabled ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enabled
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: enabled ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: enabled ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: enabled ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          available,
                          style: TextStyle(
                            color: enabled ? Colors.green[700] : Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedRedemptionType = null;
                    _qrToken = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  'Redeem Your Coffee',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Card(
                elevation: 8,
                shadowColor: Colors.black,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedRedemptionType == 'subscription'
                            ? 'Subscription Coffee'
                            : 'Joker Redemption',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Valid until midnight',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_qrToken != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: _qrToken!,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                                gapless: false,
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  border:Border.all(color: Colors.black)
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Image.asset(
                                  'assets/icons/mocha_icon_black.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ready to Redeem',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Show this QR code to the coffee shop staff to complete your redemption.',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionSubtitle(Map<String, dynamic> status) {
    final subscriptionInfo = status['subscriptionInfo'];
    if (subscriptionInfo?['hasSubscription'] == true) {
      return subscriptionInfo['bundleName'] ?? 'Active subscription';
    }
    return 'No active subscription';
  }

  String _getSubscriptionAvailable(Map<String, dynamic> status) {
    final weeklyRedemptions = status['weeklyRedemptions'] ?? 0;
    final subscriptionInfo = status['subscriptionInfo'];

    if (subscriptionInfo?['hasSubscription'] != true) {
      return 'No subscription';
    }

    final weeklyLimit = 5;
    final remaining = weeklyLimit - weeklyRedemptions;

    if (remaining <= 0) {
      return 'Weekly limit reached';
    }

    return '$remaining of $weeklyLimit this week';
  }
}