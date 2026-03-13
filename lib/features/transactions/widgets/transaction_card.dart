import 'package:flutter/material.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';

class TransactionCard extends StatelessWidget {
  final Transactions transaction;

  const TransactionCard({super.key, required this.transaction});

  Color _getAmountColor() {
    if (transaction.type == 'income') {
      return AppTheme.successColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  String _getAmountPrefix() {
    if (transaction.type == 'income') {
      return '+';
    } else {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingScreen,
        vertical: AppTheme.spacingBetween / 2,
      ),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Ícone da categoria
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: const Icon(Icons.category, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          // Descrição e data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Sem descrição',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  transaction.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Valor
          Text(
            '${_getAmountPrefix()} ${CurrencyFormatter.format(transaction.amountCents)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _getAmountColor(),
            ),
          ),
        ],
      ),
    );
  }
}
