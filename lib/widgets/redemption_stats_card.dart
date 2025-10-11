// lib/widgets/redemption_stats_card.dart - Updated with session handling

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/monthly_stats_service.dart';
import '../utils/exceptions.dart';

class CoffeeStatsCard extends StatefulWidget {
  // Optional parameters for fallback/loading states
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
      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stats = await MonthlyStatsService.getMonthlyStats();

      if (!mounted) return; // Check again after async operation

      setState(() {
        _monthlyStats = stats;
        _isLoading = false;
      });
    } on SessionExpiredException catch (e) {
      if (!mounted) return; // Check if widget is still mounted

      // Handle session expiry - show dialog and redirect to login
      if (mounted) {
        _handleSessionExpired(e.message);
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading monthly stats: $e');
    }
  }

  // New method to handle session expiry
  void _handleSessionExpired(String message) {
    if (!mounted) return;

    // Clear any loading states
    setState(() {
      _isLoading = false;
      _errorMessage = null; // Don't show generic error for session expiry
    });

    // Show session expired dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Session Expired',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513), // Coffee brown color
            ),
          ),
          content: Text(
            message.isNotEmpty
                ? message
                : 'Your session has expired. Please log in again to continue.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _redirectToLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513), // Coffee brown
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

  // Method to redirect to login screen
  void _redirectToLogin() {
    if (!mounted) return;

    // Navigate to login screen and clear navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Update with your login route name
          (route) => false, // Remove all previous routes
    );

    // Alternative if you're not using named routes:
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (context) => const LoginScreen()),
    //   (route) => false,
    // );
  }

  Future<void> _refresh() async {
    await _loadMonthlyStats();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String month = 'Loading...';
    String subtitle = 'Your Redemption Stats';

    if (_monthlyStats != null) {
      month = _monthlyStats!.month;
      if (_monthlyStats!.hasActiveSubscription && _monthlyStats!.subscriptionPlanName != null) {
        subtitle = _monthlyStats!.subscriptionPlanName!;
      }
    } else if (!_isLoading && _errorMessage == null && widget.fallbackMonth != null) {
      month = widget.fallbackMonth!;
    } else if (_errorMessage != null) {
      month = widget.fallbackMonth ?? 'Error';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                month,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: MyApp.coffeeBean,
                ),
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(MyApp.coffeeBean),
                ),
              )
            else if (_errorMessage != null)
              GestureDetector(
                onTap: _refresh,
                child: Icon(
                  Icons.refresh,
                  color: MyApp.coffeeBean,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Your Redemption Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ],
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

    // Fallback to provided values
    return _buildFallbackStatsRow();
  }

  Widget _buildLoadingState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLoadingStatItem('Remaining'),
        _buildLoadingStatItem('Redeemed'),
        _buildLoadingStatItem('Jokers'),
      ],
    );
  }

  Widget _buildLoadingStatItem(String label) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MyApp.coffeeBean.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(MyApp.coffeeBean),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'Failed to load stats',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
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
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItemWithIcon(
          context,
          _monthlyStats!.remainingMonthly.toString(),
          'Remaining',
          Icons.coffee,
          // Show different color if no remaining redemptions
          _monthlyStats!.remainingMonthly == 0 ? Colors.grey : null,
        ),
        _buildStatItemWithIcon(
          context,
          _monthlyStats!.totalRedeemed.toString(),
          'Redeemed',
          Icons.check_circle_outline,
        ),
        _buildStatItemWithIcon(
          context,
          _monthlyStats!.jokersAvailable.toString(),
          'Jokers',
          Icons.card_giftcard,
        ),
      ],
    );
  }

  Widget _buildFallbackStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItemWithIcon(
          context,
          widget.fallbackRemainingCount ?? '0',
          'Remaining',
          Icons.coffee,
        ),
        _buildStatItemWithIcon(
          context,
          widget.fallbackRedeemedCount ?? '0',
          'Redeemed',
          Icons.check_circle_outline,
        ),
        _buildStatItemWithIcon(
          context,
          widget.fallbackJokersCount ?? '0',
          'Jokers',
          Icons.card_giftcard,
        ),
      ],
    );
  }

  Widget _buildStatItemWithIcon(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      [Color? overrideColor]
      ) {
    final coffeeBean = overrideColor ?? Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: coffeeBean.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: coffeeBean,
                size: 18,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: coffeeBean,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}