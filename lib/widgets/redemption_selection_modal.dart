// lib/widgets/redemption_selection_modal.dart
// ✅ COMPLETE VERSION with comprehensive debug logging
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert'; // ✅ Add this for JSON pretty printing
import 'package:confetti/confetti.dart';
import '../config/app_typography.dart';
import '../services/redemption_service.dart';
import '../services/monthly_stats_service.dart';
import '../config/app_config.dart';
import '../utils/exceptions.dart';

class RedemptionSelectionModal extends StatefulWidget {
  final String? initialRedemptionType;

  const RedemptionSelectionModal({
    Key? key,
    this.initialRedemptionType,
  }) : super(key: key);

  @override
  State<RedemptionSelectionModal> createState() =>
      _RedemptionSelectionModalState();
}

class _RedemptionSelectionModalState extends State<RedemptionSelectionModal> {
  static const Color coffeeBrown = Color(0xFF8B4513);
  static const Color lightCream = Color(0xFFF5E6D3);
  static const Color darkBrown = Color(0xFF5D4037);
  static const Color chocolate = Color(0xFFD2691E);

  Map<String, dynamic>? _redemptionStatus;
  MonthlyStatsData? _monthlyStats;
  String? _selectedRedemptionType;
  String? _qrToken;
  bool _isLoading = false;
  String? _error;
  bool _isGeneratingQR = false;

  // Polling infrastructure
  Timer? _pollTimer;
  int _initialRedemptionCount = 0;
  bool _isPolling = false;
  DateTime? _qrGeneratedAt;

  late ConfettiController _confettiController;

  // Success state
  bool _showSuccessScreen = false;
  Map<String, dynamic>? _redemptionDetails;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _loadRedemptionStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadRedemptionStatus() async {
    if (AppConfig.enableLogging) {
      print('🔍 RedemptionModal: Loading redemption status and monthly stats');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statusResult = await RedemptionService.getRedemptionStatus();
      final monthlyStats = await MonthlyStatsService.getMonthlyStats();

      if (statusResult['success']) {
        // ✅ ENHANCED DEBUG: Pretty print the entire status object
        if (AppConfig.enableLogging) {
          print('═══════════════════════════════════════');
          print('📦 REDEMPTION STATUS RESPONSE:');
          print('═══════════════════════════════════════');
          try {
            final prettyJson =
                JsonEncoder.withIndent('  ').convert(statusResult['status']);
            print(prettyJson);
          } catch (e) {
            print('Raw status: ${statusResult['status']}');
          }
          print('═══════════════════════════════════════');
        }

        setState(() {
          _redemptionStatus = statusResult['status'];
          _monthlyStats = monthlyStats;
          _isLoading = false;
          _initialRedemptionCount = monthlyStats.totalRedeemed;
        });

        if (AppConfig.enableLogging) {
          print('✅ RedemptionModal: Data loaded successfully');
          print('   Initial redemption count: $_initialRedemptionCount');
          print('   Remaining monthly: ${monthlyStats.remainingMonthly}');
        }

        if (widget.initialRedemptionType != null && mounted) {
          _generateQRCode(widget.initialRedemptionType!);
        }
      } else {
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
          _qrGeneratedAt = DateTime.now();
        });

        _startPolling();
      } else {
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
          final timeUntilNext = RedemptionService.getTimeUntilNextRedemption(
              result['nextAvailableAt']);
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

  void _startPolling() {
    if (_isPolling) return;

    setState(() {
      _isPolling = true;
    });

    if (AppConfig.enableLogging) {
      print('🔄 Starting redemption polling...');
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkRedemptionStatus();
    });

    Future.delayed(const Duration(minutes: 5), () {
      _stopPolling();
    });
  }

  void _stopPolling() {
    if (AppConfig.enableLogging) {
      print('⏹️ Stopping redemption polling');
    }
    _pollTimer?.cancel();
    setState(() {
      _isPolling = false;
    });
  }

  Future<void> _checkRedemptionStatus() async {
    if (!mounted || _showSuccessScreen) return;

    try {
      final monthlyStats = await MonthlyStatsService.getMonthlyStats();

      if (AppConfig.enableLogging) {
        print(
            '🔍 Poll check: ${monthlyStats.totalRedeemed} vs $_initialRedemptionCount');
      }

      if (monthlyStats.totalRedeemed > _initialRedemptionCount) {
        if (AppConfig.enableLogging) {
          print('✅ Redemption detected! Showing success screen');
        }

        _stopPolling();
        _onRedemptionSuccess(monthlyStats);
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('⚠️ Polling error (continuing): $e');
      }
    }
  }

  void _onRedemptionSuccess(MonthlyStatsData updatedStats) {
    if (!mounted) return;

    setState(() {
      _showSuccessScreen = true;
      _monthlyStats = updatedStats;
      _redemptionDetails = {
        'type': _selectedRedemptionType,
        'timestamp': DateTime.now(),
        'remainingMonthly': updatedStats.remainingMonthly,
        'totalRedeemed': updatedStats.totalRedeemed,
      };
    });

    _confettiController.play();

    if (AppConfig.enableLogging) {
      print('🎉 Success screen shown with confetti!');
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: lightCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.lock_clock, color: Colors.orange, size: 28),
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
                  borderRadius: BorderRadius.circular(10),
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
        color: Color(0xFFF5F5F5),
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
    if (_showSuccessScreen) {
      return _buildSuccessScreen();
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightCream,
                borderRadius: BorderRadius.circular(10),
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

  Widget _buildSuccessScreen() {
    final details = _redemptionDetails;
    if (details == null) return const SizedBox();

    final isSubscription = details['type'] == 'subscription';
    final remainingMonthly = details['remainingMonthly'] ?? 0;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isSubscription
                              ? [coffeeBrown, chocolate]
                              : [Colors.orange[700]!, Colors.orange[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icons/mocha_icon_white.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Coffee Redeemed!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enjoy your ${isSubscription ? "subscription" : "joker"} coffee!',
                style: const TextStyle(
                  fontSize: 18,
                  color: darkBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (isSubscription) ...[
                      _buildStatRow(
                        icon: Icons.coffee,
                        label: 'Remaining This Month',
                        value: '$remainingMonthly',
                        color: coffeeBrown,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: coffeeBrown.withOpacity(0.2)),
                      const SizedBox(height: 16),
                    ],
                    _buildStatRow(
                      icon: Icons.calendar_today,
                      label: 'Total Redeemed',
                      value: '${details['totalRedeemed']}',
                      color: chocolate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coffeeBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSuccessScreen = false;
                    _qrToken = null;
                    _selectedRedemptionType = null;
                  });
                  _loadRedemptionStatus();
                },
                child: const Text(
                  'Redeem Another Coffee',
                  style: TextStyle(
                    color: coffeeBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2,
            maxBlastForce: 3,
            minBlastForce: 1,
            emissionFrequency: 0.1,
            numberOfParticles: 10,
            gravity: 0.5,
            shouldLoop: false,
            colors: const [
              coffeeBrown,
              chocolate,
              Colors.orange,
              Colors.amber,
              Colors.brown,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: darkBrown,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSessionError ? Icons.lock_clock : Icons.coffee_outlined,
              size: 80,
              color:
                  isSessionError ? Colors.orange : coffeeBrown.withOpacity(0.7),
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
        ],
      ),
    );
  }

  Widget _buildRedemptionSelection() {
    final status = _redemptionStatus;
    if (status == null) return const SizedBox();

    // ✅ DEBUG: Log everything about subscription status
    if (AppConfig.enableLogging) {
      print('═══════════════════════════════════════');
      print('🎯 BUILDING REDEMPTION SELECTION');
      print('═══════════════════════════════════════');
      print('📊 Status object type: ${status.runtimeType}');
      print('📊 Status keys: ${status.keys.toList()}');
      print('');
      print('🔍 Subscription Info Access:');
      print('   status[\'subscriptionInfo\']: ${status['subscriptionInfo']}');
      print('   Type: ${status['subscriptionInfo']?.runtimeType}');

      if (status['subscriptionInfo'] != null) {
        final subInfo = status['subscriptionInfo'];
        print('   Keys: ${subInfo.keys.toList()}');
      }
      print('');
      print('🔍 Top-level flags:');
      print(
          '   status[\'canRedeemSubscription\']: ${status['canRedeemSubscription']}'); // ✅ THIS IS WHERE IT IS
      print('   status[\'canRedeemJoker\']: ${status['canRedeemJoker']}');
      print('   status[\'jokerCount\']: ${status['jokerCount']}');
      print('');
      print('✅ Final enabled values:');
      print(
          '   Subscription enabled: ${status['canRedeemSubscription'] ?? false}'); // ✅ CORRECT ACCESS
      print('   Joker enabled: ${status['canRedeemJoker'] ?? false}');
      print('═══════════════════════════════════════');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redeem Coffee',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose your redemption type',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRedemptionOption(
            type: 'subscription',
            title: 'Free Coffee',
            subtitle: _getSubscriptionSubtitle(status),
            icon: Icons.local_cafe_rounded,
            gradient: const LinearGradient(
              colors: [AppConfig.coffeeGreen, AppConfig.coffeeGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            enabled: status['canRedeemSubscription'] ?? false,
            available: _getSubscriptionAvailable(status),
            allowedCoffeeTypes: (status['subscriptionInfo']?['allowedCoffeeTypes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList(),
          ),
          const SizedBox(height: 16),
          _buildRedemptionOption(
            type: 'joker',
            title: 'Use Joker',
            subtitle: 'Valid at any participating shop',
            icon: Icons.stars_rounded,
            gradient: LinearGradient(
              colors: [AppConfig.coffeeBean, AppConfig.coffeeBean],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
    required bool enabled,
    required String available,
    List<String>? allowedCoffeeTypes,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
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
                  padding: const EdgeInsets.all(20),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700, color: Colors.white),
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
                        style: AppTypography.titleMedium.copyWith(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
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
                              enabled
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
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
                      ),if (type == 'subscription' && enabled && allowedCoffeeTypes != null && allowedCoffeeTypes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: coffeeBrown.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: coffeeBrown.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: coffeeBrown, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Included Coffee Types',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: coffeeBrown)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: allowedCoffeeTypes.map((coffeeType) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: coffeeBrown.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: coffeeBrown.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 12, color: coffeeBrown),
                                        const SizedBox(width: 4),
                                        Text(coffeeType,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkBrown)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (type == 'subscription' && enabled) ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final expirationInfo = _getSubscriptionExpirationInfo();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: expirationInfo['backgroundColor'] as Color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (expirationInfo['color'] as Color).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    expirationInfo['icon'] as IconData,
                                    color: expirationInfo['color'] as Color,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    expirationInfo['text'] as String,
                                    style: TextStyle(
                                      color: expirationInfo['color'] as Color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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
                    _stopPolling();
                    setState(() {
                      _selectedRedemptionType = null;
                      _qrToken = null;
                    });
                  },
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: coffeeBrown),
                ),
              ),
              Expanded(
                child: Text(
                  'Your Coffee QR',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
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
                          ? [AppConfig.coffeeGreen, AppConfig.coffeeGreen]
                          : [AppConfig.coffeeBean, AppConfig.coffeeBean],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 12),
                        Text( // Remove Expanded wrapper
                          _selectedRedemptionType == 'subscription'
                              ? 'Free Coffee'
                              : 'Use Joker',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: coffeeBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time,
                                    color: coffeeBrown, size: 14),
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
                          if (_isPolling) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green[700]!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Waiting',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _isPolling
                          ? Icons.qr_code_scanner
                          : Icons.info_outline_rounded,
                      color: coffeeBrown,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _isPolling
                            ? 'Show this QR code to the coffee shop. We\'ll automatically detect when it\'s scanned!'
                            : 'Show this QR code to the coffee shop staff to complete your redemption.',
                        style: const TextStyle(
                          color: darkBrown,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isPolling) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_tethering,
                          color: Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Monitoring redemption status...',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionSubtitle(Map<String, dynamic> status) {
    if (_monthlyStats?.hasActiveSubscription == true) {
      final shopName = _monthlyStats?.coffeeShopName;
      final planName = _monthlyStats?.subscriptionPlanName;

      if (shopName != null && planName != null) {
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

  String _getSubscriptionAvailable(Map<String, dynamic> status) {
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

    if (AppConfig.enableLogging) {
      print('📊 Subscription Available Calculation:');
      print('   Remaining monthly: $remainingMonthly');
    }

    if (remainingMonthly <= 0) {
      return 'Monthly limit reached';
    }

    return '$remainingMonthly remaining';
  }

  Map<String, dynamic> _getSubscriptionExpirationInfo() {
    // Try to get expiration from redemption status
    final subscriptionInfo = _redemptionStatus?['subscriptionInfo'];
    if (subscriptionInfo != null && subscriptionInfo['endDate'] != null) {
      try {
        final endDate = DateTime.parse(subscriptionInfo['endDate']);
        final now = DateTime.now();
        final daysRemaining = endDate.difference(now).inDays;

        // Determine color based on days remaining
        Color color;
        Color backgroundColor;
        IconData icon;

        if (daysRemaining < 0) {
          // Expired
          color = Colors.red[700]!;
          backgroundColor = Colors.red.withOpacity(0.1);
          icon = Icons.error_outline;
          return {
            'text': 'Expired',
            'color': color,
            'backgroundColor': backgroundColor,
            'icon': icon,
          };
        } else if (daysRemaining == 0) {
          // Expires today
          color = Colors.red[700]!;
          backgroundColor = Colors.red.withOpacity(0.1);
          icon = Icons.warning_amber_rounded;
          return {
            'text': 'Expires today',
            'color': color,
            'backgroundColor': backgroundColor,
            'icon': icon,
          };
        } else if (daysRemaining == 1) {
          // Expires tomorrow
          color = Colors.orange[700]!;
          backgroundColor = Colors.orange.withOpacity(0.1);
          icon = Icons.warning_amber_rounded;
          return {
            'text': 'Expires tomorrow',
            'color': color,
            'backgroundColor': backgroundColor,
            'icon': icon,
          };
        } else if (daysRemaining <= 3) {
          // Expires within 3 days - urgent
          color = Colors.orange[700]!;
          backgroundColor = Colors.orange.withOpacity(0.1);
          icon = Icons.schedule;
          return {
            'text': 'Expires in $daysRemaining days',
            'color': color,
            'backgroundColor': backgroundColor,
            'icon': icon,
          };
        } else if (daysRemaining <= 7) {
          // Expires within a week - warning
          color = Colors.amber[700]!;
          backgroundColor = Colors.amber.withOpacity(0.1);
          icon = Icons.schedule;
          return {
            'text': 'Expires in $daysRemaining days',
            'color': color,
            'backgroundColor': backgroundColor,
            'icon': icon,
          };
        } else {
          // More than a week - all good
          color = Colors.green[700]!;
          backgroundColor = Colors.green.withOpacity(0.1);
          icon = Icons.check_circle_outline;

          // Format as "Expires Dec 31, 2025"
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return {
            'text': 'Expires ${months[endDate.month - 1]} ${endDate.day}, ${endDate.year}',
            'color': color,
            'backgroundColor': backgroundColor,
            'icon': icon,
          };
        }
      } catch (e) {
        if (AppConfig.enableLogging) {
          print('⚠️ Error parsing expiration date: $e');
        }
      }
    }

    // Fallback
    return {
      'text': 'Active subscription',
      'color': darkBrown.withOpacity(0.7),
      'backgroundColor': darkBrown.withOpacity(0.05),
      'icon': Icons.calendar_today,
    };
  }
}
