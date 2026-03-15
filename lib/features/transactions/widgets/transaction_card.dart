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

  String _getTypeLabel() {
    if (transaction.type == 'income') return 'Receita';
    if (transaction.type == 'investment') return 'Investimento';
    return 'Despesa';
  }

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
              child: Icon(Icons.delete_outline_rounded,
                  color: colorScheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir transação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
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
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
            ),
            child: const Text('Excluir',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(Icons.edit_outlined,
                      size: 18, color: colorScheme.primary),
                ),
                title: Text('Editar transação',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface)),
                subtitle: Text('Alterar dados desta transação',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEdit?.call();
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: colorScheme.error),
                ),
                title: Text('Excluir transação',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error)),
                subtitle: Text('Esta ação não pode ser desfeita',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5))),
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
    final hasNote = transaction.note != null && transaction.note!.isNotEmpty;
    final isRecurring = transaction.isRecurring;
    final isPending = transaction.status == 'pending';

    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingScreen, vertical: 4),
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
            const Text('Excluir',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingScreen, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Linha principal ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingCard, 12, AppTheme.paddingCard, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ícone do tipo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    child: Icon(typeIcon, size: 20, color: typeColor),
                  ),
                  const SizedBox(width: 12),

                  // Descrição + tipo
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
                        Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color: typeColor.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Valor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getAmountPrefix()} ${CurrencyFormatter.format(transaction.amountCents)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: typeColor,
                        ),
                      ),
                      // Badge de status inline com o valor
                      if (isPending)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'pendente',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Menu
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

            // ── Linha de detalhes (sempre visível) ───────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingCard, 8, AppTheme.paddingCard, 10),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.03),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusCard),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data + recorrente
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12,
                          color: colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 5),
                      Text(
                        transaction.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                      if (isRecurring) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.repeat_rounded,
                            size: 12,
                            color: colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          'recorrente',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                      // Parcelas
                      if (transaction.installmentTotal != null &&
                          transaction.installmentTotal! > 1) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.layers_rounded,
                            size: 12,
                            color: colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          '${transaction.installmentCurrent ?? 1}/${transaction.installmentTotal}x',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Nota (só se existir)
                  if (hasNote) ...[
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 12,
                            color: colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            transaction.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.55),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
