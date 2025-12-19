import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';

import '../app/providers/stats_provider.dart';
import '../app/storage/local_storage.dart';
import 'TableExportButton.dart';

class PartnerTransactionsTable extends ConsumerStatefulWidget {
  final String partnerId;
  final int maxVisibleItems;
  final double maxHeight;

  const PartnerTransactionsTable({
    super.key,
    required this.partnerId,
    this.maxVisibleItems = 5,
    this.maxHeight = 400,
  });

  @override
  ConsumerState<PartnerTransactionsTable> createState() =>
      _PartnerTransactionsTableState();
}

class _PartnerTransactionsTableState
    extends ConsumerState<PartnerTransactionsTable> {
  String? _token;
  List<Map<String, dynamic>> _currentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await LocalStorage.getToken();
    if (mounted) {
      setState(() => _token = token);
    }
  }

  List<List<String>> _getTransactionsRows() {
    return _currentTransactions.map((tx) {
      final type = tx['type']?.toString() ?? 'N/A';
      final points = tx['amount_points']?.toString() ?? '0';
      final source = tx['source']?.toString() ?? 'N/A';
      final branch = tx['branch_name']?.toString() ?? 'Global';
      final createdAt = tx['created_at']?.toString();
      String formattedDate = 'N/A';
      if (createdAt != null) {
        try {
          formattedDate = DateFormat(
            'MMM dd, yyyy HH:mm',
          ).format(DateTime.parse(createdAt));
        } catch (_) {}
      }
      return [type, points, source, branch, formattedDate];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: _buildLoadingState(),
      );
    }

    final transactionsAsync = ref.watch(
      partnerTransactionsProvider((
        partnerId: widget.partnerId,
        token: _token!,
      )),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Points Transactions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Earn & Redeem history",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Export Button
              TableExportButton(
                headers: ['Type', 'Points', 'Source', 'Branch', 'Date'],
                getRows: _getTransactionsRows,
                fileName: 'points_transactions',
                reportTitle: 'Points Transactions Report',
                hasData: _currentTransactions.isNotEmpty,
              ),
              const SizedBox(width: 8),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00D4AA)),
                  onPressed: () => ref.refresh(
                    partnerTransactionsProvider((
                      partnerId: widget.partnerId,
                      token: _token!,
                    )),
                  ),
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content
          transactionsAsync.when(
            data: (transactions) {
              _currentTransactions = transactions;
              return _buildTransactionsList(transactions);
            },
            loading: () => _buildLoadingState(),
            error: (err, stack) => _buildErrorState(err.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    const double itemHeight = 60.0;
    const double separatorHeight = 1.0;
    final int itemsToShow = transactions.length > widget.maxVisibleItems
        ? widget.maxVisibleItems
        : transactions.length;

    final double calculatedHeight =
        (itemHeight * itemsToShow) + (separatorHeight * (itemsToShow - 1));
    final double finalHeight = calculatedHeight > widget.maxHeight
        ? widget.maxHeight
        : calculatedHeight;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: itemHeight,
        maxHeight: finalHeight.clamp(itemHeight, widget.maxHeight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: transactions.length > widget.maxVisibleItems
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return _buildTransactionCard(tx);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final type = tx['type']?.toString().toUpperCase() ?? 'N/A';
    final points = (tx['amount_points'] as num?)?.toInt() ?? 0;
    final source = tx['source']?.toString() ?? 'N/A';
    final branch = tx['branch_name']?.toString() ?? 'Global';
    final createdAt = tx['created_at']?.toString();

    String formattedDate = 'N/A';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      } catch (_) {}
    }

    final isEarn = type == 'EARN';
    final typeColor = isEarn
        ? const Color(0xFF00D4AA)
        : const Color(0xFFFF6B9D);
    final typeIcon = isEarn ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Type Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LineIcons.mapMarker,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      branch,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 12),
                    Icon(LineIcons.calendar, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Points
          Text(
            '${isEarn ? '+' : '-'}$points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LineIcons.coins,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Points activity will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
