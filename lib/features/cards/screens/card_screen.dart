import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/credit_cards.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  Color _hexToColor(String? hex, {Color fallback = const Color(0xFF0D1B2A)}) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return fallback;
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Color _darken(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _fallbackColor(String keyword) {
    final k = keyword.toLowerCase();
    if (k.contains('nubank')) return const Color(0xFF8B5CF6);
    if (k.contains('inter')) return const Color(0xFFFF6B00);
    if (k.contains('bradesco')) return const Color(0xFFCC0000);
    if (k.contains('itau')) return const Color(0xFFFF6600);
    if (k.contains('santander')) return const Color(0xFFEC0000);
    if (k.contains('c6')) return const Color(0xFF1A1A2E);
    if (k.contains('xp')) return const Color(0xFF000000);
    return AppTheme.primaryColor;
  }

  Color _cardColor(CreditCards card) {
    if (card.colorHex != null && card.colorHex!.isNotEmpty) {
      return _hexToColor(card.colorHex);
    }
    return _fallbackColor(card.bankKeyword);
  }

  void _showAddCardSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    final bankController = TextEditingController();
    final closingController = TextEditingController();
    final dueController = TextEditingController();
    final limitMask = InputMasks.currency();
    String? pickedHex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text('Adicionar cartão',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
              const Gap(4),
              Text('Preencha os dados do cartão',
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.55))),
              const Gap(20),
              _SheetField(
                  controller: nameController,
                  label: 'Nome do cartão',
                  icon: Icons.credit_card_rounded),
              const Gap(12),
              _SheetField(
                  controller: bankController,
                  label: 'Banco (ex: nubank)',
                  icon: Icons.account_balance_rounded),
              const Gap(12),
              _SheetField(
                  controller: limitController,
                  label: 'Limite (R\$)',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [limitMask]),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                        controller: closingController,
                        label: 'Dia fechamento',
                        icon: Icons.event_rounded,
                        keyboardType: TextInputType.number),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _SheetField(
                        controller: dueController,
                        label: 'Dia vencimento',
                        icon: Icons.event_available_rounded,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip)),
                  ),
                  onPressed: () async {
                    final limitValue = InputMasks.currencyToCents(limitController.text);
                    final newCard = CreditCards(
                      name: nameController.text,
                      totalLimitCents: limitValue,
                      closingDay: int.tryParse(closingController.text) ?? 1,
                      dueDay: int.tryParse(dueController.text) ?? 10,
                      colorHex: pickedHex,
                      bankKeyword: bankController.text.toLowerCase(),
                    );
                    await DatabaseHelper.instance.insertCreditCards(newCard);
                    ref.invalidate(creditCardProvider);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Adicionar cartão',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCardSheet(CreditCards card) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController(text: card.name);
    final limitController = TextEditingController(
        text: InputMasks.centsToCurrencyText(card.totalLimitCents));
    final bankController = TextEditingController(text: card.bankKeyword);
    final closingController =
        TextEditingController(text: card.closingDay.toString());
    final dueController = TextEditingController(text: card.dueDay.toString());
    final limitMask = InputMasks.currency();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text('Editar cartão',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
              const Gap(4),
              Text('Altere os dados do cartão',
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.55))),
              const Gap(20),
              _SheetField(
                  controller: nameController,
                  label: 'Nome do cartão',
                  icon: Icons.credit_card_rounded),
              const Gap(12),
              _SheetField(
                  controller: bankController,
                  label: 'Banco (ex: nubank)',
                  icon: Icons.account_balance_rounded),
              const Gap(12),
              _SheetField(
                  controller: limitController,
                  label: 'Limite (R\$)',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [limitMask]),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                        controller: closingController,
                        label: 'Dia fechamento',
                        icon: Icons.event_rounded,
                        keyboardType: TextInputType.number),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _SheetField(
                        controller: dueController,
                        label: 'Dia vencimento',
                        icon: Icons.event_available_rounded,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip)),
                  ),
                  onPressed: () async {
                    final limitValue = InputMasks.currencyToCents(limitController.text);
                    final updated = CreditCards(
                      id: card.id,
                      name: nameController.text.isNotEmpty
                          ? nameController.text
                          : card.name,
                      totalLimitCents: limitValue > 0
                          ? limitValue
                          : card.totalLimitCents,
                      closingDay: int.tryParse(closingController.text) ??
                          card.closingDay,
                      dueDay: int.tryParse(dueController.text) ?? card.dueDay,
                      colorHex: card.colorHex,
                      bankKeyword: bankController.text.isNotEmpty
                          ? bankController.text.toLowerCase()
                          : card.bankKeyword,
                    );
                    await DatabaseHelper.instance.updateCreditCards(updated);
                    ref.invalidate(creditCardProvider);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Salvar alterações',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(CreditCards card) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            child: Icon(Icons.delete_outline_rounded,
                color: colorScheme.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Remover cartão',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface))),
        ]),
        content: Text('Tem certeza que deseja remover o cartão "${card.name}"?',
            style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.4)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withOpacity(0.6)),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCreditCards(card.id!);
              ref.invalidate(creditCardProvider);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            ),
            child: const Text('Remover',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardsAsync = ref.watch(creditCardProvider);
    return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: false,
          title: Text('Meus Cartões',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showAddCardSheet,
                icon: Icon(Icons.add_rounded,
                    size: 18, color: colorScheme.primary),
                label: Text('Adicionar',
                    style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
        body: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (cards) => cards.isEmpty
              ? _buildEmpty(colorScheme)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppTheme.paddingScreen, 8, AppTheme.paddingScreen, 100),
                  children: [
                    ...List.generate(cards.length, (i) {
                      final color = _cardColor(cards[i]);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CreditCardWidget(
                          card: cards[i],
                          baseColor: color,
                          darkColor: _darken(color),
                          onEdit: () => _showEditCardSheet(cards[i]),
                          onDelete: () => _showDeleteConfirm(cards[i]),
                        ),
                      );
                    }),
                    const Gap(8),
                    Text('RESUMO',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: colorScheme.onSurface.withOpacity(0.45))),
                    const Gap(10),
                    ...List.generate(cards.length, (i) {
                      final color = _cardColor(cards[i]);
                      return _CardSummaryTile(card: cards[i], baseColor: color);
                    }),
                  ],
                ),
        ));
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.credit_card_rounded,
                size: 48, color: colorScheme.primary.withOpacity(0.5)),
          ),
          const Gap(16),
          Text('Nenhum cartão cadastrado',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
          const Gap(6),
          Text('Adicione um cartão para rastrear seus gastos',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: colorScheme.onSurface.withOpacity(0.5))),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: _showAddCardSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Adicionar cartão',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card visual
// ---------------------------------------------------------------------------

class _CreditCardWidget extends ConsumerWidget {
  final CreditCards card;
  final Color baseColor;
  final Color darkColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CreditCardWidget({
    required this.card,
    required this.baseColor,
    required this.darkColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = card.id == null
        ? const AsyncValue<CardLimitDetails>.data(
            CardLimitDetails(usedCents: 0, dynamicLimitCents: 0),
          )
        : ref.watch(cardLimitDetailsProvider(card.id!));

    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, darkColor],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              right: -30,
              top: -30,
              child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle))),
          Positioned(
              right: 40,
              bottom: -50,
              child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(card.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CardIconButton(
                            icon: Icons.edit_outlined, onTap: onEdit),
                        const SizedBox(width: 8),
                        _CardIconButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: onDelete),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(card.bankKeyword.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600)),
                const Gap(6),
                detailsAsync.when(
                  loading: () => const LinearProgressIndicator(
                    minHeight: 6,
                    value: null,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  error: (_, __) => Text(
                    'Limite indisponível',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  data: (details) {
                    final total = details.dynamicLimitCents;
                    final used = details.usedCents;
                    final available = details.availableCents;
                    final percent =
                        (details.usedPercent * 100).toStringAsFixed(0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limite Total: ${CurrencyFormatter.format(total)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const Gap(6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: details.usedPercent,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Disponível: ${CurrencyFormatter.format(available)}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12),
                            ),
                            Text(
                              '$percent% utilizado',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          'Usado: ${CurrencyFormatter.format(used)}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
                const Gap(10),
                Row(
                  children: [
                    _CardInfoPill(
                        label: 'Fecha dia ${card.closingDay}',
                        icon: Icons.event_rounded),
                    const SizedBox(width: 8),
                    _CardInfoPill(
                        label: 'Vence dia ${card.dueDay}',
                        icon: Icons.event_available_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CardIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _CardInfoPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CardInfoPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile de resumo
// ---------------------------------------------------------------------------

class _CardSummaryTile extends ConsumerWidget {
  final CreditCards card;
  final Color baseColor;

  const _CardSummaryTile({required this.card, required this.baseColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final detailsAsync = card.id == null
        ? const AsyncValue<CardLimitDetails>.data(
            CardLimitDetails(usedCents: 0, dynamicLimitCents: 0),
          )
        : ref.watch(cardLimitDetailsProvider(card.id!));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(Icons.credit_card_rounded, color: baseColor, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: detailsAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 4),
              error: (_, __) => Text(card.name),
              data: (details) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface)),
                      Text('${(details.usedPercent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface)),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    'Disponível: ${CurrencyFormatter.format(details.availableCents)}\nUsado: ${CurrencyFormatter.format(details.usedCents)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.55)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares dos sheets
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        labelStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide:
              BorderSide(color: colorScheme.onSurface.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
      ),
    );
  }
}
