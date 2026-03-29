import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';

/// Card visual de uma transação na lista da home.
///
/// Responsabilidades DESTE widget:
///   - Exibir os dados da transação
///   - Swipe para deletar (Dismissible)
///   - Bottom sheet com opções (editar / excluir)
///
/// Responsabilidades do PAI (transactions_screen):
///   - Lógica de qual dialog mostrar (simples / recorrente / parcelado)
///   - Invalidar providers após delete
///
/// Por que separar assim?
/// O card não sabe se a transação é parte de um grupo ou recorrente no
/// contexto da lista. Quem sabe isso é a tela. Então a lógica de "o que
/// acontece no delete" fica na tela via callbacks.
class TransactionCard extends StatefulWidget {
  final Transactions transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onActivateSelection;
  final VoidCallback? onToggleSelection;

  /// Callback chamado ANTES de deletar — retorna true se deve prosseguir.
  /// Recebe o BuildContext para poder mostrar dialogs.
  /// Se null, mostra um dialog de confirmação simples interno.
  final Future<bool> Function(BuildContext context)? onDeleteWithContext;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.onDeleteWithContext,
    this.selectionMode = false,
    this.isSelected = false,
    this.onActivateSelection,
    this.onToggleSelection,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
    with SingleTickerProviderStateMixin {
  Timer? _longPressTimer;
  bool _selectionJustActivated = false;
  bool _didHapticSwipeCue = false;

  // Swipe-to-action state
  late AnimationController _swipeCtrl;
  late Animation<double> _swipeAnim;
  double _rawOffset = 0;
  bool _isDragging = false;

  double get _swipeOffset => _isDragging ? _rawOffset : _swipeAnim.value;

  // ─── Helpers visuais ──────────────────────────────────────────────────────

  Color _typeColor() {
    switch (widget.transaction.type) {
      case 'income':
        return const Color(0xFF2ECC71);
      case 'investment':
        return Colors.blueAccent;
      default:
        return Colors.redAccent;
    }
  }

  IconData _typeIcon() {
    switch (widget.transaction.type) {
      case 'income':
        return Icons.arrow_upward_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.arrow_downward_rounded;
    }
  }

  String _typeLabel() {
    switch (widget.transaction.type) {
      case 'income':
        return 'Receita';
      case 'investment':
        return 'Investimento';
      default:
        return 'Despesa';
    }
  }

  String _amountPrefix() => widget.transaction.type == 'income' ? '+' : '-';

  /// Converte 'yyyy-MM-dd' → 'dd/MM/yyyy' sem depender de intl.
  String _fmtDate(String raw) {
    final p = raw.split('-');
    if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    return raw;
  }

  void _startSelectionHoldTimer() {
    if (widget.selectionMode || widget.onActivateSelection == null) return;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(seconds: 1), () {
      _selectionJustActivated = true;
      HapticFeedback.mediumImpact();
      widget.onActivateSelection?.call();
    });
  }

  void _cancelSelectionHoldTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _swipeAnim = const AlwaysStoppedAnimation(0);
  }

  void _animateSwipeTo(double target) {
    final from = _swipeOffset;
    _swipeAnim = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeOutCubic),
    );
    _isDragging = false;
    _swipeCtrl.forward(from: 0);
  }

  void _snapSwipeBack() => _animateSwipeTo(0);

  Future<void> _handleDeleteTap(BuildContext context) async {
    _snapSwipeBack();
    final bool ok;
    if (widget.onDeleteWithContext != null) {
      ok = await widget.onDeleteWithContext!(context);
    } else {
      ok = await _confirmDelete(context);
    }
    if (ok) widget.onDelete?.call();
  }

  @override
  void dispose() {
    _swipeCtrl.dispose();
    _cancelSelectionHoldTimer();
    super.dispose();
  }

  // ─── Dialog de confirmação simples (fallback quando onDeleteWithContext == null)
  //
  // Este dialog é mais simples do que os da transactions_screen — não tem
  // lógica de recorrência/parcelamento. Serve apenas como confirmação básica.
  Future<bool> _confirmDelete(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child:
                  Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir transação',
                style: AppTheme.titleStyle(context, fontSize: 16),
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
              style: AppTheme.subtitleStyle(
                context,
                fontSize: 14,
                color: cs.onSurface.withAlpha(178),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Preview da transação que será deletada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.onSurface.withAlpha(13),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.transaction.description?.isNotEmpty == true
                          ? widget.transaction.description!
                          : 'Sem descrição',
                      style: AppTheme.actionStyle(context, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_amountPrefix()} ${CurrencyFormatter.format(widget.transaction.amountCents)}',
                    style: AppTheme.titleStyle(
                      context,
                      fontSize: 13,
                      color: _typeColor(),
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
              foregroundColor: cs.onSurface.withAlpha(153),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            ),
            child: const Text('Excluir',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ─── Bottom sheet de opções ───────────────────────────────────────────────

  void _showOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeColor = _typeColor();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withAlpha(38),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Preview da transação
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingScreen, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: typeColor.withAlpha(31),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Icon(_typeIcon(), size: 16, color: typeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.transaction.description?.isNotEmpty == true
                            ? widget.transaction.description!
                            : 'Sem descrição',
                        style: AppTheme.actionStyle(context, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_amountPrefix()} ${CurrencyFormatter.format(widget.transaction.amountCents)}',
                      style: AppTheme.titleStyle(
                        context,
                        fontSize: 14,
                        color: typeColor,
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
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                ),
                title: Text('Editar transação',
                    style: AppTheme.actionStyle(context, fontSize: 14)),
                subtitle: Text('Alterar dados desta transação',
                    style: AppTheme.metaStyle(
                      context,
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(127),
                    )),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onEdit?.call();
                },
              ),

              // Opção: Excluir
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: cs.error),
                ),
                title: Text('Excluir transação',
                    style: AppTheme.actionStyle(
                      context,
                      fontSize: 14,
                      color: cs.error,
                    )),
                subtitle: Text('Esta ação não pode ser desfeita',
                    style: AppTheme.metaStyle(
                      context,
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(127),
                    )),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  // Usa o callback do pai (com lógica de recorrência/parcelas)
                  // ou o dialog simples como fallback
                  final shouldDelete = widget.onDeleteWithContext != null
                      ? await widget.onDeleteWithContext!(context)
                      : await _confirmDelete(context);
                  if (shouldDelete) widget.onDelete?.call();
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _swipeCtrl,
        builder: (context, _) {
          final cs = Theme.of(context).colorScheme;
          final offset = _swipeOffset;
          // Limita o offset a 60% do card para não separar visualmente
          const maxRevealFraction = 0.6;
          return LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  constraints.maxWidth - AppTheme.paddingScreen * 2;
              final maxLeft = cardWidth * maxRevealFraction;
              final maxRight = widget.onEdit != null ? 72.0 : 0.0;
              // Progresso de 0..1 para cada direção
              final deleteProgress =
                  (offset < 0 ? (-offset / maxLeft).clamp(0.0, 1.0) : 0.0);
              final editProgress =
                  (offset > 0 ? (offset / maxRight).clamp(0.0, 1.0) : 0.0);
              return GestureDetector(
                onHorizontalDragStart: (_) {
                  if (widget.selectionMode) return;
                  _cancelSelectionHoldTimer();
                  _swipeCtrl.stop();
                  setState(() {
                    _isDragging = true;
                    _rawOffset = _swipeOffset;
                  });
                },
                onHorizontalDragUpdate: (d) {
                  if (widget.selectionMode) return;
                  final next =
                      (_rawOffset + d.delta.dx).clamp(-maxLeft, maxRight);
                  setState(() => _rawOffset = next);
                  // haptic ao cruzar 50% de reveal
                  if (next < -maxLeft * 0.5 && !_didHapticSwipeCue) {
                    _didHapticSwipeCue = true;
                    HapticFeedback.lightImpact();
                  } else if (next >= -maxLeft * 0.5 && _didHapticSwipeCue) {
                    _didHapticSwipeCue = false;
                  }
                },
                onHorizontalDragEnd: (d) {
                  if (widget.selectionMode) return;
                  final vel = d.primaryVelocity ?? 0;
                  // Swipe para direita → editar
                  if ((_rawOffset > maxRight * 0.5 || vel > 600) &&
                      widget.onEdit != null) {
                    HapticFeedback.selectionClick();
                    _snapSwipeBack();
                    widget.onEdit?.call();
                    _didHapticSwipeCue = false;
                    return;
                  }
                  // Swipe para esquerda → deletar
                  if (_rawOffset < -maxLeft * 0.45 || vel < -600) {
                    HapticFeedback.mediumImpact();
                    _snapSwipeBack();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _handleDeleteTap(context);
                    });
                    _didHapticSwipeCue = false;
                    return;
                  }
                  _snapSwipeBack();
                  _didHapticSwipeCue = false;
                },
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // ── Fundo DELETE — Positioned.fill com offsets idênticos
                    // ao margin do card → mesma altura garantida
                    if (!widget.selectionMode && offset < 0)
                      Positioned(
                        left: AppTheme.paddingScreen,
                        right: AppTheme.paddingScreen,
                        top: 4,
                        bottom: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.error,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusCard),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 20 + deleteProgress * 4,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Excluir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // ── Fundo EDIT — mesma lógica
                    if (!widget.selectionMode &&
                        widget.onEdit != null &&
                        offset > 0)
                      Positioned(
                        left: AppTheme.paddingScreen,
                        right: AppTheme.paddingScreen,
                        top: 4,
                        bottom: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusCard),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: cs.onPrimary,
                                size: 20 + editProgress * 4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Editar',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // ── Card deslizando por cima
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: _buildCard(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeColor = _typeColor();
    final hasNote =
        widget.transaction.note != null && widget.transaction.note!.isNotEmpty;
    final isPending = widget.transaction.status == 'pending';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!widget.selectionMode) _startSelectionHoldTimer();
      },
      onTapUp: (_) => _cancelSelectionHoldTimer(),
      onTapCancel: _cancelSelectionHoldTimer,
      onTap: () {
        if (_selectionJustActivated) {
          _selectionJustActivated = false;
          return;
        }
        if (widget.selectionMode) {
          widget.onToggleSelection?.call();
        }
      },
      child: AnimatedScale(
        scale: widget.isSelected ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingScreen, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected ? cs.primary.withAlpha(10) : cs.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: widget.isSelected
                  ? cs.primary.withAlpha(120)
                  : cs.onSurface.withAlpha(20),
              width: widget.isSelected ? 1.6 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Linha principal ──────────────────────────────────────
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
                            color: typeColor.withAlpha(31),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                          ),
                          child: Icon(_typeIcon(), size: 20, color: typeColor),
                        ),
                        const SizedBox(width: 12),

                        // Descrição + tipo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.transaction.description?.isNotEmpty ==
                                        true
                                    ? widget.transaction.description!
                                    : 'Sem descrição',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: cs.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _typeLabel(),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: typeColor.withAlpha(217),
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Valor + badge de pendente
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_amountPrefix()} ${CurrencyFormatter.format(widget.transaction.amountCents)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: typeColor),
                            ),
                            if (isPending)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withAlpha(31),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'pendente',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentColor),
                                ),
                              ),
                          ],
                        ),

                        // Botão de opções
                        const SizedBox(width: 4),
                        if (!widget.selectionMode)
                          GestureDetector(
                            onTap: () => _showOptions(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: cs.onSurface.withAlpha(89),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 22),
                      ],
                    ),
                  ),

                  // ── Linha de detalhes ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.paddingCard, 8, AppTheme.paddingCard, 10),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(8),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppTheme.radiusCard)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Data + badges de recorrência/parcelas
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 12, color: cs.onSurface.withAlpha(102)),
                            const SizedBox(width: 5),
                            Text(
                              _fmtDate(widget.transaction.date),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withAlpha(140)),
                            ),
                            if (widget.transaction.isRecurring) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.repeat_rounded,
                                  size: 12, color: cs.onSurface.withAlpha(102)),
                              const SizedBox(width: 4),
                              Text('recorrente',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface.withAlpha(140))),
                            ],
                            if ((widget.transaction.installmentTotal ?? 0) >
                                1) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.layers_rounded,
                                  size: 12, color: cs.onSurface.withAlpha(102)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.transaction.installmentCurrent ?? 1}/${widget.transaction.installmentTotal}x',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withAlpha(140)),
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
                                  size: 12, color: cs.onSurface.withAlpha(102)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  widget.transaction.note!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface.withAlpha(140),
                                      fontStyle: FontStyle.italic),
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
              if (widget.selectionMode)
                Positioned(
                  top: 10,
                  right: 10,
                  child: AnimatedScale(
                    scale: widget.isSelected ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 180),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: widget.isSelected ? cs.primary : cs.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: widget.isSelected
                              ? cs.primary
                              : cs.onSurface.withAlpha(80),
                        ),
                      ),
                      child: widget.isSelected
                          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
