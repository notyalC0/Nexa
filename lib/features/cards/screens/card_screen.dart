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
  // ─── Helpers de cor ─────────────────────────────────────────────────────

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
    if (k.contains('itau') || k.contains('itaú')) return const Color(0xFFFF6600);
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

  // ─── Sheets ─────────────────────────────────────────────────────────────

  void _showCardSheet({CreditCards? existing}) {
    final isEdit = existing != null;
    final colorScheme = Theme.of(context).colorScheme;

    // Controladores inicializados com valores existentes (se edição)
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final limitController = TextEditingController(
      text: existing != null
          ? InputMasks.centsToCurrencyText(existing.totalLimitCents)
          : '',
    );
    final bankController =
        TextEditingController(text: existing?.bankKeyword ?? '');
    final closingController = TextEditingController(
        text: existing?.closingDay.toString() ?? '');
    final dueController =
        TextEditingController(text: existing?.dueDay.toString() ?? '');

    final limitMask = InputMasks.currency();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusModal)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingScreen,
          right: AppTheme.paddingScreen,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHandle(),
                Text(
                  isEdit ? 'Editar cartão' : 'Adicionar cartão',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface),
                ),
                const Gap(4),
                Text(
                  isEdit
                      ? 'Altere os dados do cartão'
                      : 'Preencha os dados do cartão',
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withAlpha(140)),
                ),
                const Gap(20),

                // Nome
                _SheetField(
                  controller: nameController,
                  label: 'Nome do cartão',
                  icon: Icons.credit_card_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const Gap(12),

                // Banco
                _SheetField(
                  controller: bankController,
                  label: 'Banco (ex: nubank, itau)',
                  icon: Icons.account_balance_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o banco' : null,
                ),
                const Gap(12),

                // Limite
                _SheetField(
                  controller: limitController,
                  label: 'Limite (R\$)',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [limitMask],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o limite';
                    if (InputMasks.currencyToCents(v) <= 0) {
                      return 'Limite deve ser maior que zero';
                    }
                    return null;
                  },
                ),
                const Gap(12),

                // Dias — lado a lado com validação de 1–31
                Row(
                  children: [
                    Expanded(
                      child: _SheetField(
                        controller: closingController,
                        label: 'Dia fechamento',
                        icon: Icons.event_rounded,
                        keyboardType: TextInputType.number,
                        // Limita a 2 dígitos e só números
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: _validateDay,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _SheetField(
                        controller: dueController,
                        label: 'Dia vencimento',
                        icon: Icons.event_available_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: _validateDay,
                      ),
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
                      if (!formKey.currentState!.validate()) return;

                      final limitValue =
                          InputMasks.currencyToCents(limitController.text);
                      final closingDay =
                          int.parse(closingController.text.trim());
                      final dueDay = int.parse(dueController.text.trim());

                      if (isEdit) {
                        final updated = CreditCards(
                          id: existing!.id,
                          name: nameController.text.trim(),
                          totalLimitCents: limitValue,
                          closingDay: closingDay,
                          dueDay: dueDay,
                          colorHex: existing.colorHex,
                          bankKeyword:
                              bankController.text.trim().toLowerCase(),
                        );
                        await DatabaseHelper.instance
                            .updateCreditCards(updated);
                      } else {
                        final newCard = CreditCards(
                          name: nameController.text.trim(),
                          totalLimitCents: limitValue,
                          closingDay: closingDay,
                          dueDay: dueDay,
                          bankKeyword:
                              bankController.text.trim().toLowerCase(),
                        );
                        await DatabaseHelper.instance
                            .insertCreditCards(newCard);
                      }

                      ref.invalidate(creditCardProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      isEdit ? 'Salvar alterações' : 'Adicionar cartão',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Valida se o dia informado está entre 1 e 31
  String? _validateDay(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o dia';
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 31) {
      return 'Dia inválido (1–31)';
    }
    return null;
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
              color: colorScheme.error.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(Icons.delete_outline_rounded,
                color: colorScheme.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Remover cartão',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface),
            ),
          ),
        ]),
        content: Text(
          'Tem certeza que deseja remover o cartão "${card.name}"?\n\nAs transações vinculadas a ele não serão excluídas.',
          style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withAlpha(178),
              height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withAlpha(153)),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCreditCards(card.id!);
              ref.invalidate(creditCardProvider);
              if (ctx.mounted) Navigator.pop(ctx);
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

  // ─── Build ──────────────────────────────────────────────────────────────

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
        title: Text(
          'Meus Cartões',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showCardSheet(),
              icon: Icon(Icons.add_rounded,
                  size: 18, color: colorScheme.primary),
              label: Text(
                'Adicionar',
                style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (cards) => cards.isEmpty
            ? _buildEmpty(colorScheme)
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.paddingScreen,
                    8,
                    AppTheme.paddingScreen,
                    100),
                children: [
                  // Cartões visuais
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CreditCardWidget(
                        card: card,
                        baseColor: _cardColor(card),
                        darkColor: _darken(_cardColor(card)),
                        onEdit: () => _showCardSheet(existing: card),
                        onDelete: () => _showDeleteConfirm(card),
                      ),
                    ),

                  const Gap(8),
                  Text(
                    'RESUMO',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withAlpha(115)),
                  ),
                  const Gap(10),

                  // Tiles de resumo
                  for (final card in cards)
                    _CardSummaryTile(
                        card: card, baseColor: _cardColor(card)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.credit_card_rounded,
                size: 48,
                color: colorScheme.primary.withAlpha(127)),
          ),
          const Gap(16),
          Text(
            'Nenhum cartão cadastrado',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
          const Gap(6),
          Text(
            'Adicione um cartão para rastrear seus gastos',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(127)),
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () => _showCardSheet(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Adicionar cartão',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusChip)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CreditCardWidget ────────────────────────────────────────────────────────

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
            CardLimitDetails(usedCents: 0, dynamicLimitCents: 0))
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
            color: darkColor.withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos de fundo
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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

                // Banco
                Text(
                  card.bankKeyword.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(140),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600),
                ),
                const Gap(6),

                // Limite
                detailsAsync.when(
                  loading: () => const LinearProgressIndicator(
                    minHeight: 6,
                    value: null,
                    backgroundColor: Colors.white24,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  error: (_, __) => Text(
                    'Limite indisponível',
                    style: TextStyle(color: Colors.white.withAlpha(204)),
                  ),
                  data: (details) {
                    final percent =
                        (details.usedPercent * 100).toStringAsFixed(0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limite Total: ${CurrencyFormatter.format(details.dynamicLimitCents)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                        const Gap(6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: details.usedPercent,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Disponível: ${CurrencyFormatter.format(details.availableCents)}',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(230),
                                  fontSize: 12),
                            ),
                            Text(
                              '$percent% utilizado',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(217),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          'Usado: ${CurrencyFormatter.format(details.usedCents)}',
                          style: TextStyle(
                              color: Colors.white.withAlpha(230),
                              fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),

                const Gap(10),

                // Info pills: fechamento e vencimento
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
          color: Colors.white.withAlpha(38),
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
        color: Colors.white.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withAlpha(204)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(230),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── CardSummaryTile ─────────────────────────────────────────────────────────

class _CardSummaryTile extends ConsumerWidget {
  final CreditCards card;
  final Color baseColor;

  const _CardSummaryTile({required this.card, required this.baseColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final detailsAsync = card.id == null
        ? const AsyncValue<CardLimitDetails>.data(
            CardLimitDetails(usedCents: 0, dynamicLimitCents: 0))
        : ref.watch(cardLimitDetailsProvider(card.id!));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border:
            Border.all(color: colorScheme.onSurface.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: baseColor.withAlpha(31),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(Icons.credit_card_rounded,
                color: baseColor, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: detailsAsync.when(
              loading: () =>
                  const LinearProgressIndicator(minHeight: 4),
              error: (_, __) => Text(card.name),
              data: (details) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(details.usedPercent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    'Disponível: ${CurrencyFormatter.format(details.availableCents)}'
                    '   Usado: ${CurrencyFormatter.format(details.usedCents)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(140)),
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

// ─── Widgets auxiliares dos sheets ───────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(38),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Campo de texto reutilizável dos bottom sheets.
///
/// Agora recebe `validator` para suportar validação com Form.
class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            size: 18,
            color: colorScheme.onSurface.withAlpha(127)),
        filled: true,
        fillColor:
            colorScheme.surfaceContainerHighest.withAlpha(102),
        labelStyle: TextStyle(
            color: colorScheme.onSurface.withAlpha(140), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide:
              BorderSide(color: colorScheme.onSurface.withAlpha(31)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide:
              BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide:
              BorderSide(color: colorScheme.error, width: 1.8),
        ),
      ),
    );
  }
}
