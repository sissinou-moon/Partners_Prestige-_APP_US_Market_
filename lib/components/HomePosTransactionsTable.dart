import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers/stats_provider.dart';
import 'TableExportButton.dart';

class PosTransactionsTable extends ConsumerStatefulWidget {
  final String partnerId;
  final String? branchId;
  final int maxVisibleItems;
  final double maxHeight;

  const PosTransactionsTable({
    super.key,
    required this.partnerId,
    this.branchId,
    this.maxVisibleItems = 5,
    this.maxHeight = 500,
  });

  @override
  ConsumerState<PosTransactionsTable> createState() =>
      _PosTransactionsTableState();
}

class _PosTransactionsTableState extends ConsumerState<PosTransactionsTable> {
  List<Map<String, dynamic>> _currentTransactions = [];

  List<List<String>> _getTransactionRows() {
    return _currentTransactions.map((tx) {
      final amount = (tx['amount_value'] as num?)?.toDouble() ?? 0.0;
      final currency = tx['currency']?.toString() ?? 'USD';
      final type = tx['type']?.toString() ?? 'PAYMENT';
      final customer = tx['pos_costomer']?.toString() ?? 'Unknown';
      final txId = tx['external_tx_id']?.toString() ?? 'N/A';
      final receivedAt = tx['received_at']?.toString();

      String formattedDate = 'N/A';
      if (receivedAt != null) {
        try {
          formattedDate = DateFormat(
            'MMM dd, yyyy HH:mm',
          ).format(DateTime.parse(receivedAt));
        } catch (_) {}
      }

      return [
        customer,
        type,
        _formatCurrency(amount, currency),
        txId,
        formattedDate,
      ];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final params = PosTransactionParams(
      partnerId: widget.partnerId,
      branchId: widget.branchId,
    );

    final posAsync = ref.watch(posTransactionsProvider(params));

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
                      "Recent Transactions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "POS transaction history",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Export Button
              TableExportButton(
                headers: ['Customer', 'Type', 'Amount', 'TX ID', 'Date'],
                getRows: _getTransactionRows,
                fileName: 'pos_transactions',
                reportTitle: 'POS Transactions Report',
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
                  onPressed: () => ref.refresh(posTransactionsProvider(params)),
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content with responsive height
          posAsync.when(
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
      return SizedBox(
        height: 250,
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
                  Icons.receipt_long_outlined,
                  size: 64,
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
                'Transactions will appear here once processed',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate responsive height based on number of items
    const double itemHeight = 60.0; // Approximate height per item
    const double separatorHeight = 1.0;
    final int itemsToShow = transactions.length > widget.maxVisibleItems
        ? widget.maxVisibleItems
        : transactions.length;

    final double calculatedHeight =
        (itemHeight * itemsToShow) + (separatorHeight * (itemsToShow - 1));

    // Use the smaller of calculated height or maxHeight
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
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return _buildTransactionCard(tx);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amount = (tx['amount_value'] as num?)?.toDouble() ?? 0.0;
    final currency = tx['currency']?.toString() ?? 'USD';
    final type = tx['type']?.toString() ?? 'PAYMENT';
    final customer = tx['pos_costomer']?.toString() ?? 'Unknown';
    final txId = tx['external_tx_id']?.toString() ?? 'N/A';
    final receivedAt = tx['received_at']?.toString();

    String formattedDate = 'N/A';
    if (receivedAt != null) {
      try {
        final date = DateTime.parse(receivedAt);
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    final typeColor = _getTypeColor(type);
    final isRefund = type.toUpperCase() == 'REFUND';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_getTypeIcon(type), color: typeColor, size: 15),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 60,
            child: Text(
              'ID: $txId',
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Amount
          Text(
            '${isRefund ? '-' : '+'}${_formatCurrency(amount, currency)}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isRefund ? Colors.red : const Color(0xFF00D4AA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon skeleton
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(width: 10),
          // Details skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 70,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 80,
            height: 20,
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
      height: 250,
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
                size: 64,
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return const Color(0xFF00D4AA);
      case 'REFUND':
        return const Color(0xFFFF6B9D);
      case 'VOID':
        return const Color(0xFFFFB020);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return Icons.arrow_upward;
      case 'REFUND':
        return Icons.arrow_downward;
      case 'VOID':
        return Icons.block;
      default:
        return Icons.receipt;
    }
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : currency,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
