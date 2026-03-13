import 'package:flutter/material.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';

class TransactionCard extends StatelessWidget {
  final Transactions transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  Color _getTypeColor() {
    if (transaction.type == 'income') return const Color(0xFF2ECC71);
    if (transaction.type == 'investment') return Colors.blueAccent;
    return Colors.redAccent;
  }

  IconData _getTypeIcon() {
    if (transaction.type == 'income') return Icons.arrow_upward_rounded;
    if (transaction.type == 'investment') return Icons.trending_up_rounded;
    return Icons.arrow_downward_rounded;
  }

  String _getAmountPrefix() => transaction.type == 'income' ? '+' : '-';

  Future<bool> _confirmDelete(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusModal),
        ),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Excluir transação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir esta transação?',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Preview da transação no dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.description != null &&
                              transaction.description!.isNotEmpty
                          ? transaction.description!
                          : 'Sem descrição',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_getAmountPrefix()} ${CurrencyFormatter.format(transaction.amountCents)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _getTypeColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
            ),
            child: const Text(
              'Excluir',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return result == true;
  }

  void _showOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusModal),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle visual
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Preview no bottom sheet
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingScreen, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Icon(_getTypeIcon(),
                          size: 16, color: _getTypeColor()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transaction.description != null &&
                                transaction.description!.isNotEmpty
                            ? transaction.description!
                            : 'Sem descrição',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_getAmountPrefix()} ${CurrencyFormatter.format(transaction.amountCents)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _getTypeColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              // Opção: Editar
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Editar transação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Alterar dados desta transação',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEdit?.call();
                },
              ),
              // Opção: Excluir
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                ),
                title: Text(
                  'Excluir transação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Text(
                  'Esta ação não pode ser desfeita',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await _confirmDelete(context);
                  if (confirmed) onDelete?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _getTypeColor();
    final typeIcon = _getTypeIcon();

    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.hashCode),
      direction: DismissDirection.endToStart,
      // Fundo vermelho que aparece ao arrastar
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingScreen,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              'Excluir',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      // Confirmação antes de dispensar
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingScreen,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingCard,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Ícone do tipo ---
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Icon(typeIcon, size: 20, color: typeColor),
            ),
            const SizedBox(width: 12),

            // --- Descrição e data ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transaction.description != null &&
                            transaction.description!.isNotEmpty
                        ? transaction.description!
                        : 'Sem descrição',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          transaction.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...[
                        const SizedBox(width: 6),
                        _StatusDot(status: transaction.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // --- Valor ---
            Text(
              '${_getAmountPrefix()} ${CurrencyFormatter.format(transaction.amountCents)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: typeColor,
              ),
            ),

            // --- Menu de opções ---
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showOptions(context),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final color = isPending ? AppTheme.accentColor : const Color(0xFF2ECC71);
    final label = isPending ? 'pendente' : 'confirmado';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
