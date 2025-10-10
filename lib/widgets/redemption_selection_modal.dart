// lib/widgets/redemption_selection_modal.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/redemption_service.dart';
import '../services/monthly_stats_service.dart'; // ✅ ADDED
import '../config/app_config.dart';
import '../utils/exceptions.dart'; // ✅ ADDED

class RedemptionSelectionModal extends StatefulWidget {
  final String? initialRedemptionType;

  const RedemptionSelectionModal({
    Key? key,
    this.initialRedemptionType,
  }) : super(key: key);

  @override
  State<RedemptionSelectionModal> createState() => _RedemptionSelectionModalState();
}

class _RedemptionSelectionModalState extends State<RedemptionSelectionModal> {
  static const Color coffeeBrown = Color(0xFF8B4513);
  static const Color lightCream = Color(0xFFF5E6D3);
  static const Color darkBrown = Color(0xFF5D4037);
  static const Color chocolate = Color(0xFFD2691E);

  Map<String, dynamic>? _redemptionStatus;
  MonthlyStatsData? _monthlyStats; // ✅ ADDED: State variable for monthly stats
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

  // ✅ UPDATED: Now fetches both redemption status AND monthly stats
  Future<void> _loadRedemptionStatus() async {
    if (AppConfig.enableLogging) {
      print('🔍 RedemptionModal: Loading redemption status and monthly stats');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both data sources
      final statusResult = await RedemptionService.getRedemptionStatus();
      final monthlyStats = await MonthlyStatsService.getMonthlyStats(); // ✅ ADDED

      if (statusResult['success']) {
        setState(() {
          _redemptionStatus = statusResult['status'];
          _monthlyStats = monthlyStats; // ✅ ADDED: Store monthly stats
          _isLoading = false;
        });

        if (AppConfig.enableLogging) {
          print('✅ RedemptionModal: Data loaded successfully');
          print('   Remaining monthly: ${monthlyStats.remainingMonthly}');
          print('   Total redeemed: ${monthlyStats.totalRedeemed}');
          print('   Has subscription: ${monthlyStats.hasActiveSubscription}');
        }

        if (widget.initialRedemptionType != null && mounted) {
          _generateQRCode(widget.initialRedemptionType!);
        }
      } else {
        if (AppConfig.enableLogging) {
          print('❌ RedemptionModal: Failed to load status');
        }

        if (statusResult['isSessionExpired'] == true ||
            statusResult['errorCode'] == 'SESSION_EXPIRED' ||
            statusResult['errorCode'] == 'TOKEN_EXPIRED') {
          Navigator.of(context).pop();
          _showSessionExpiredDialog();
          return;
        }

        setState(() {
          _error = statusResult['error'] ?? 'Unknown error from server';
          _isLoading = false;
        });
      }
    } on SessionExpiredException catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ RedemptionModal: Session expired - $e');
      }
      Navigator.of(context).pop();
      _showSessionExpiredDialog();
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
        backgroundColor: lightCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_clock, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Session Expired',
                style: TextStyle(
                  color: coffeeBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your session has expired for security reasons. Please log in again to continue enjoying your coffee!',
          style: TextStyle(
            color: darkBrown,
            fontSize: 16,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: coffeeBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              },
              child: const Text(
                'Login Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            lightCream,
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: coffeeBrown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightCream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(coffeeBrown),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Preparing your coffee...',
              style: TextStyle(
                color: coffeeBrown,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSessionError ? Icons.lock_clock : Icons.coffee_outlined,
              size: 80,
              color: isSessionError ? Colors.orange : coffeeBrown.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSessionError ? 'Session Expired' : 'Oops!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: coffeeBrown,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: 16,
              color: darkBrown,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (!isSessionError)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: coffeeBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: _loadRedemptionStatus,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isSessionError)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                        (route) => false,
                  );
                },
                child: const Text(
                  'Login Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRedemptionSelection() {
    final status = _redemptionStatus;
    if (status == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/icons/mocha_icon_black.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redeem Coffee',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose your redemption type',
                      style: TextStyle(
                        fontSize: 14,
                        color: darkBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildRedemptionOption(
            type: 'subscription',
            title: 'Subscription Coffee',
            subtitle: _getSubscriptionSubtitle(status),
            icon: Icons.local_cafe_rounded,
            gradient: const LinearGradient(
              colors: [coffeeBrown, chocolate],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            gradientPosition: 'top',
            enabled: status['canRedeemSubscription'] ?? false,
            available: _getSubscriptionAvailable(status),
          ),
          const SizedBox(height: 16),
          _buildRedemptionOption(
            type: 'joker',
            title: 'Use Joker',
            subtitle: 'Valid at any participating shop',
            icon: Icons.stars_rounded,
            gradient: LinearGradient(
              colors: [Colors.orange[700]!, Colors.orange[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            gradientPosition: 'bottom',
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
    required Gradient gradient,
    required String gradientPosition,
    required bool enabled,
    required String available,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? () => _generateQRCode(type) : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: enabled
                        ? gradient
                        : LinearGradient(
                      colors: [Colors.grey[300]!, Colors.grey[200]!],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: enabled ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (enabled)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: enabled ? coffeeBrown : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: enabled
                              ? coffeeBrown.withOpacity(0.1)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: enabled ? coffeeBrown : Colors.grey[500],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              available,
                              style: TextStyle(
                                color: enabled ? coffeeBrown : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildQRCodeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: lightCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedRedemptionType = null;
                      _qrToken = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: coffeeBrown),
                ),
              ),
              const Expanded(
                child: Text(
                  'Your Coffee QR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedRedemptionType == 'subscription'
                          ? [coffeeBrown, chocolate]
                          : [Colors.orange[700]!, Colors.orange[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedRedemptionType == 'subscription'
                              ? Icons.local_cafe_rounded
                              : Icons.stars_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedRedemptionType == 'subscription'
                              ? 'Subscription Coffee'
                              : 'Joker Redemption',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: coffeeBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: coffeeBrown, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Valid until midnight',
                              style: TextStyle(
                                color: coffeeBrown,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_qrToken != null)
                        QrImageView(
                          data: _qrToken!,
                          version: QrVersions.auto,
                          size: 240.0,
                          backgroundColor: Colors.white,
                          gapless: false,
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ready to Redeem',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: coffeeBrown.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: coffeeBrown,
                  size: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Show this QR code to the coffee shop staff to complete your redemption.',
                    style: TextStyle(
                      color: darkBrown,
                      fontSize: 14,
                      height: 1.5,
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

  // ✅ UPDATED: Uses monthly stats for subscription plan name
  String _getSubscriptionSubtitle(Map<String, dynamic> status) {
    if (_monthlyStats?.hasActiveSubscription == true) {
      // Get both coffee shop name and subscription plan name
      final shopName = _monthlyStats?.coffeeShopName;
      final planName = _monthlyStats?.subscriptionPlanName;

      if (shopName != null && planName != null) {
        // Return formatted string with shop name first, then plan name
        return '$shopName\n$planName';
      } else if (planName != null) {
        return planName;
      } else if (shopName != null) {
        return shopName;
      }
      return 'Active subscription';
    }

    final subscriptionInfo = status['subscriptionInfo'];
    if (subscriptionInfo?['hasSubscription'] == true) {
      return subscriptionInfo['bundleName'] ?? 'Active subscription';
    }
    return 'No active subscription';
  }

  // ✅ COMPLETELY REWRITTEN: Uses MonthlyStatsData directly
  String _getSubscriptionAvailable(Map<String, dynamic> status) {
    // Use monthly stats data which matches the working stats card
    if (_monthlyStats == null) {
      if (AppConfig.enableLogging) {
        print('⚠️ Monthly stats not loaded yet');
      }
      return 'Loading...';
    }

    if (!_monthlyStats!.hasActiveSubscription) {
      if (AppConfig.enableLogging) {
        print('ℹ️ No active subscription');
      }
      return 'No subscription';
    }

    final remainingMonthly = _monthlyStats!.remainingMonthly;
    final totalRedeemed = _monthlyStats!.totalRedeemed;

    if (AppConfig.enableLogging) {
      print('📊 Subscription Available Calculation:');
      print('   Remaining monthly: $remainingMonthly');
      print('   Total redeemed: $totalRedeemed');
      print('   Has subscription: ${_monthlyStats!.hasActiveSubscription}');
    }

    if (remainingMonthly <= 0) {
      return 'Monthly limit reached';
    }

    // Calculate monthly limit from remaining + redeemed
    final monthlyLimit = remainingMonthly + totalRedeemed;

    return '$remainingMonthly remaining this month';
  }
}