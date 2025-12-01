// lib/widgets/redemption_stats_card.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mocha_point/main.dart';
import '../services/monthly_stats_service.dart';
import '../utils/exceptions.dart';
import '../config/app_typography.dart';

class CoffeeStatsCard extends StatefulWidget {
  final String? fallbackMonth;
  final String? fallbackRedeemedCount;
  final String? fallbackRemainingCount;
  final String? fallbackJokersCount;
  final VoidCallback? onRefreshRequested;

  const CoffeeStatsCard({
    super.key,
    this.fallbackMonth,
    this.fallbackRedeemedCount,
    this.fallbackRemainingCount,
    this.fallbackJokersCount,
    this.onRefreshRequested,
  });

  @override
  State<CoffeeStatsCard> createState() => _CoffeeStatsCardState();
}

class _CoffeeStatsCardState extends State<CoffeeStatsCard> {
  MonthlyStatsData? _monthlyStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMonthlyStats();
  }

  void refresh() {
    _loadMonthlyStats();
  }

  Future<void> _loadMonthlyStats() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stats = await MonthlyStatsService.getMonthlyStats();

      if (!mounted) return;

      setState(() {
        _monthlyStats = stats;
        _isLoading = false;
      });
    } on SessionExpiredException catch (e) {
      if (!mounted) return;

      if (mounted) {
        _handleSessionExpired(e.message);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading monthly stats: $e');
    }
  }

  void _handleSessionExpired(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Session Expired',
            style: AppTypography.headlineSmall.copyWith(
              color: const Color(0xFF462919),
            ),
          ),
          content: Text(
            message.isNotEmpty
                ? message
                : 'Your session has expired. Please log in again to continue.',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF462919),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Log In Again'),
            ),
          ],
        );
      },
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  Future<void> _refresh() async {
    await _loadMonthlyStats();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _buildStatsContent(),
    );
  }

  Widget _buildStatsContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_monthlyStats != null) {
      return _buildStatsRow();
    }

    return _buildFallbackStatsRow();
  }

  Widget _buildLoadingState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLoadingStatItem(),
        _buildLoadingStatItem(),
        _buildLoadingStatItem(),
      ],
    );
  }

  Widget _buildLoadingStatItem() {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey.shade700,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load stats',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyApp.coffeeBean,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final monthlyLimit = _monthlyStats!.monthlyLimit ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          icon: Icons.local_cafe_outlined,
          label: 'REMAINING',
          value: _monthlyStats!.remainingMonthly.toString(),
        ),
        _buildStatItem(
          icon: Icons.check_circle_outline,
          label: 'REDEEMED',
          value: _monthlyStats!.totalRedeemed.toString(),
        ),
        _buildStatItem(
          icon: Icons.card_giftcard,
          label: 'JOKERS',
          value: _monthlyStats!.jokersAvailable.toString(),
        ),
      ],
    );
  }

  Widget _buildFallbackStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          icon: Icons.local_cafe_outlined,
          label: 'REMAINING',
          value: widget.fallbackRemainingCount ?? '0',
        ),
        _buildStatItem(
          icon: Icons.check_circle_outline,
          label: 'REDEEMED',
          value: widget.fallbackRedeemedCount ?? '0',
          subtitle: 'THIS PERIOD',
        ),
        _buildStatItem(
          icon: Icons.card_giftcard,
          label: 'JOKERS',
          value: widget.fallbackJokersCount ?? '0',
          subtitle: 'ACTIVE',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(1),
                  Colors.white.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: MyApp.coffeeAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}