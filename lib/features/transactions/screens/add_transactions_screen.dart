import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/credit_cards.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/cards/screens/card_screen.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/categories.dart';
import '../../../core/models/transactions.dart';

class AddTransactionsScreen extends ConsumerStatefulWidget {
  final Transactions? transaction;

  const AddTransactionsScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionsScreen> createState() =>
      _AddTransactionsScreenState();
}

class _AddTransactionsScreenState extends ConsumerState<AddTransactionsScreen> {
  // ─── Controladores ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _installmentController = TextEditingController();
  final _installmentCurrentController = TextEditingController();
  late final _currencyMask = InputMasks.currency();

  // ─── Estado ─────────────────────────────────────────────────────────────
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedDateForDb;
  int? _selectedCardId;
  int? _selectedCategoryId;
  bool _isRecurring = false;
  bool _triedToSave = false;

  // ─── Dados estáticos ────────────────────────────────────────────────────
  static const _types = [
    _TxType(
        'expense', 'Despesa', Icons.arrow_downward_rounded, Colors.redAccent),
    _TxType('income', 'Receita', Icons.arrow_upward_rounded, Color(0xFF2ECC71)),
  ];

  // ─── Ciclo de vida ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    final tx = widget.transaction;
    if (tx != null) {
      // Modo edição: preenche com os dados existentes
      _amountController.text = InputMasks.centsToCurrencyText(tx.amountCents);
      _selectedType = tx.type;
      _selectedStatus = tx.status;
      _selectedCardId = tx.creditCardsId;
      _selectedCategoryId = tx.categoryID;
      _descriptionController.text = tx.description ?? '';
      _noteController.text = tx.note ?? '';
      _isRecurring = tx.isRecurring;
      _installmentController.text = tx.installmentTotal?.toString() ?? '';
      _installmentCurrentController.text =
          tx.installmentCurrent?.toString() ?? '1';

      final date = DateFormat('yyyy-MM-dd').parse(tx.date);
      _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      _selectedDateForDb = tx.date;

      // Para parceladas: busca o total do grupo para exibir no campo de valor
      final groupId = tx.installmentGroupId;
      if ((tx.installmentTotal ?? 1) > 1 &&
          groupId != null &&
          groupId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final total = await DatabaseHelper.instance
              .getInstallmentGroupTotalAmount(groupId);
          if (!mounted) return;
          setState(() {
            _amountController.text = InputMasks.centsToCurrencyText(total);
          });
        });
      }
    } else {
      // Modo criação: valores padrão
      _selectedStatus = 'confirmed';
      _installmentCurrentController.text = '1';
      final now = DateTime.now();
      _selectedDateForDb = DateFormat('yyyy-MM-dd').format(now);
      _dateController.text = DateFormat('dd/MM/yyyy').format(now);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _installmentController.dispose();
    _installmentCurrentController.dispose();
    super.dispose();
  }

  // ─── Lógica de salvamento ────────────────────────────────────────────────

  /// Divide o valor total entre as parcelas de forma justa.
  ///
  /// Ex: R$10 em 3 parcelas → [R$3,34, R$3,33, R$3,33]
  /// O centavo "sobrando" vai para a primeira parcela.
  List<int> _splitAmount(int totalCents, int installments) {
    final safe = installments <= 0 ? 1 : installments;
    final base = totalCents ~/ safe;
    final remainder = totalCents % safe;
    return List<int>.generate(safe, (i) => base + (i < remainder ? 1 : 0),
        growable: false);
  }

  int? _resolveCategoryId(List<Categories> categories) {
    if (_selectedCategoryId != null &&
        categories.any((c) => c.id == _selectedCategoryId)) {
      return _selectedCategoryId;
    }
    // Fallback: "Sem categoria"
    for (final c in categories) {
      if (c.name.toLowerCase() == 'sem categoria') return c.id;
    }
    return categories.isNotEmpty ? categories.first.id : null;
  }

  /// Invalida todos os providers afetados por uma transação.
  void _invalidateAll() {
    ref.invalidate(transactionsByMonthProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(healthScoreProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(cardLimitDetailsProvider);
  }

  Future<void> _save() async {
    setState(() => _triedToSave = true);

    // Validação manual do tipo (não é campo de formulário padrão)
    if (_selectedType == null) return;

    if (!_formKey.currentState!.validate()) return;

    final categories = await DatabaseHelper.instance.getCategories();
    final categoryId = _resolveCategoryId(categories);
    if (categoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.snackBar(
            context,
            message: 'Nenhuma categoria disponível.',
            icon: Icons.category_outlined,
          ),
        );
      }
      return;
    }

    final amount = InputMasks.currencyToCents(_amountController.text);
    final totalParcelas = int.tryParse(_installmentController.text.trim()) ?? 1;
    final parcelaAtual =
        (int.tryParse(_installmentCurrentController.text.trim()) ?? 1)
            .clamp(1, totalParcelas);

    final recurringId = _isRecurring
        ? (widget.transaction?.recurringId ?? const Uuid().v4())
        : null;
    final recurringParentId = _isRecurring
        ? (widget.transaction?.parentId ?? widget.transaction?.id)
        : null;

    final db = DatabaseHelper.instance;

    // ── CASO 1: Nova transação parcelada ─────────────────────────────────
    if (widget.transaction == null && totalParcelas > 1) {
      final groupId = const Uuid().v4();
      final baseDate = DateFormat('yyyy-MM-dd').parse(_selectedDateForDb!);
      final amounts = _splitAmount(amount, totalParcelas);

      for (int i = 0; i < totalParcelas; i++) {
        final parcelaDate =
            DateTime(baseDate.year, baseDate.month + i, baseDate.day);
        await db.insertTransaction(Transactions(
          amountCents: amounts[i],
          type: _selectedType!,
          status: _selectedStatus ?? 'confirmed',
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: DateFormat('yyyy-MM-dd').format(parcelaDate),
          categoryID: categoryId,
          creditCardsId: _selectedCardId,
          installmentTotal: totalParcelas,
          installmentCurrent: i + 1,
          installmentGroupId: groupId,
          isRecurring: false,
          recurringId: null,
          parentId: null,
          createdFromNotification: false,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ));
      }
    }
    // ── CASO 2: Edição de compra parcelada → atualiza todo o grupo ───────
    else if (widget.transaction != null &&
        (widget.transaction!.installmentTotal ?? 1) > 1 &&
        (widget.transaction!.installmentGroupId?.isNotEmpty ?? false)) {
      final installments = await db
          .getInstallmentsByGroup(widget.transaction!.installmentGroupId!);
      if (installments.isNotEmpty) {
        final amounts = _splitAmount(amount, installments.length);
        for (int i = 0; i < installments.length; i++) {
          final inst = installments[i];
          await db.updateTransaction(Transactions(
            id: inst.id,
            amountCents: amounts[i],
            type: _selectedType!,
            status: _selectedStatus ?? 'confirmed',
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            date: inst.date,
            categoryID: categoryId,
            creditCardsId: _selectedCardId,
            installmentTotal: installments.length,
            installmentCurrent: i + 1,
            installmentGroupId: widget.transaction!.installmentGroupId,
            isRecurring: _isRecurring,
            recurringId: recurringId,
            parentId: inst.parentId ?? recurringParentId,
            createdFromNotification: inst.createdFromNotification,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            createdAt: inst.createdAt,
          ));
        }
      }
    }
    // ── CASO 3: Transação simples (nova ou edição) ────────────────────────
    else {
      final amounts = _splitAmount(amount, totalParcelas);
      final tx = Transactions(
        id: widget.transaction?.id,
        amountCents: amounts.first,
        type: _selectedType!,
        status: _selectedStatus ?? 'confirmed',
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDateForDb ??
            widget.transaction?.date ??
            _dateController.text,
        categoryID: categoryId,
        creditCardsId: _selectedCardId,
        installmentTotal: totalParcelas > 1 ? totalParcelas : null,
        installmentCurrent: totalParcelas > 1 ? parcelaAtual : null,
        installmentGroupId:
            totalParcelas > 1 ? widget.transaction?.installmentGroupId : null,
        isRecurring: _isRecurring,
        recurringId: recurringId,
        parentId: recurringParentId,
        createdFromNotification: false,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (widget.transaction != null) {
        await db.updateTransaction(tx);
      } else {
        await db.insertTransaction(tx);
      }
    }

    _invalidateAll();
    if (mounted) Navigator.pop(context);
  }

  // ─── Decorações de campo ─────────────────────────────────────────────────

  /// Campo em largura total (com ícone)
  InputDecoration _dec(String label, {IconData? icon}) {
    return AppTheme.inputDecoration(
      context,
      label: label,
      icon: icon,
    );
  }

  /// Campo compacto (sem ícone, para uso lado a lado)
  InputDecoration _decCompact(String label) {
    return AppTheme.inputDecoration(
      context,
      label: label,
      compact: true,
    );
  }

  String _statusLabel(String? value) {
    switch (value) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
      default:
        return 'Confirmado';
    }
  }

  Future<void> _openStatusPicker() async {
    final selected = await _showChoiceSheet<String>(
      title: 'Selecionar status',
      selectedValue: _selectedStatus ?? 'confirmed',
      choices: const [
        _PickerChoice(value: 'pending', label: 'Pendente'),
        _PickerChoice(value: 'confirmed', label: 'Confirmado'),
      ],
    );
    if (selected == null) return;
    setState(() => _selectedStatus = selected);
  }

  Future<void> _openCardPicker(List<CreditCards> cards) async {
    final selected = await _showChoiceSheet<int>(
      title: 'Selecionar cartão',
      selectedValue: _selectedCardId ?? -1,
      choices: [
        const _PickerChoice(
          value: -1,
          label: 'Nenhum (débito/dinheiro)',
          icon: Icons.account_balance_wallet_outlined,
        ),
        ...cards.map(
          (c) => _PickerChoice<int>(
            value: c.id ?? -1,
            label: c.name,
            subtitle:
                'Fechamento dia ${c.closingDay} • Vencimento dia ${c.dueDay}',
            icon: Icons.credit_card_rounded,
          ),
        ),
      ],
    );
    if (selected == null) return;
    setState(() {
      _selectedCardId = selected == -1 ? null : selected;
      if (_selectedCardId == null) {
        _installmentController.clear();
        _installmentCurrentController.text = '1';
      }
    });
  }

  Future<void> _openCategoryPicker(List<Categories> categories) async {
    final initial = categories.any((c) => c.id == _selectedCategoryId)
        ? _selectedCategoryId
        : categories.firstOrNull?.id;
    final selected = await _showChoiceSheet<int>(
      title: 'Selecionar categoria',
      selectedValue: initial,
      choices: categories
          .map(
            (c) => _PickerChoice<int>(
              value: c.id!,
              label: c.name,
              icon: Icons.category_rounded,
            ),
          )
          .toList(growable: false),
    );
    if (selected == null) return;
    setState(() => _selectedCategoryId = selected);
  }

  Future<T?> _showChoiceSheet<T>({
    required String title,
    required List<_PickerChoice<T>> choices,
    T? selectedValue,
  }) {
    final cs = Theme.of(context).colorScheme;

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: cs.surface,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusModal),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.titleStyle(context, fontSize: 17),
              ),
              const Gap(12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: choices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final choice = choices[index];
                    final selected =
                        selectedValue != null && choice.value == selectedValue;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      leading: choice.icon != null
                          ? Icon(
                              choice.icon,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withAlpha(166),
                            )
                          : null,
                      title: Text(
                        choice.label,
                        style: AppTheme.actionStyle(
                          context,
                          color: selected ? cs.primary : null,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: choice.subtitle == null
                          ? null
                          : Text(
                              choice.subtitle!,
                              style: AppTheme.metaStyle(context, fontSize: 12),
                            ),
                      trailing: selected
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, choice.value),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _selectionField({
    required String label,
    required String text,
    required VoidCallback? onTap,
    IconData? icon,
    Widget? suffix,
    bool compact = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: IgnorePointer(
        child: TextFormField(
          enabled: onTap != null,
          readOnly: true,
          style: AppTheme.inputTextStyle(context),
          decoration:
              (compact ? _decCompact(label) : _dec(label, icon: icon)).copyWith(
            hintText: text,
            hintStyle: AppTheme.subtitleStyle(
              context,
              fontSize: 15,
              color: onTap == null ? cs.onSurface.withAlpha(102) : cs.onSurface,
            ),
            suffixIcon: suffix ??
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurface.withAlpha(166),
                ),
          ),
        ),
      ),
    );
  }

  Future<void> _goToCardsAndRefresh() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CardsScreen()),
    );
    if (!mounted) return;
    ref.invalidate(creditCardProvider);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardsAsync = ref.watch(creditCardProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingScreen, 0, AppTheme.paddingScreen, 40),
          children: [
            // ── Cabeçalho ──────────────────────────────────────────────
            Text(
              widget.transaction != null
                  ? 'Editar Transação'
                  : 'Nova Transação',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            Text(
              'Preencha os dados abaixo',
              style:
                  TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 14),
            ),
            const Gap(28),

            // ── Valor ──────────────────────────────────────────────────
            _SectionLabel('Valor'),
            const Gap(8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTheme.inputTextStyle(
                context,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              decoration: _dec('Valor').copyWith(
                labelText: null,
                prefixText: 'R\$ ',
                prefixStyle: AppTheme.inputPrefixStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                hintText: '0,00',
                hintStyle: AppTheme.subtitleStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              inputFormatters: [_currencyMask],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe um valor';
                if (InputMasks.currencyToCents(v) <= 0) {
                  return 'Valor deve ser maior que zero';
                }
                return null;
              },
            ),
            const Gap(24),

            // ── Tipo ───────────────────────────────────────────────────
            _SectionLabel('Tipo'),
            const Gap(10),
            Row(
              children: _types.asMap().entries.map((entry) {
                final idx = entry.key;
                final type = entry.value;
                final isSelected = _selectedType == type.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedType = type.value;
                      _triedToSave = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                          right: idx < _types.length - 1 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type.color.withAlpha(38)
                            : cs.surfaceContainerHighest.withAlpha(102),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                        border: Border.all(
                          color: isSelected ? type.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(type.icon,
                              color: isSelected
                                  ? type.color
                                  : AppTheme.textSecondary,
                              size: 20),
                          const Gap(5),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? type.color
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_triedToSave && _selectedType == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Selecione um tipo',
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ),
            const Gap(24),

            // ── Detalhes: Status + Data ────────────────────────────────
            _SectionLabel('Detalhes'),
            const Gap(10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _selectionField(
                    compact: true,
                    label: 'Status',
                    text: _statusLabel(_selectedStatus),
                    onTap: _openStatusPicker,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    style: AppTheme.inputTextStyle(context),
                    cursorColor: cs.primary,
                    decoration: _decCompact('Data'),
                    readOnly: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a data' : null,
                    onTap: () async {
                      final initial = _selectedDateForDb != null
                          ? DateFormat('yyyy-MM-dd').parse(_selectedDateForDb!)
                          : DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateController.text =
                              DateFormat('dd/MM/yyyy').format(picked);
                          _selectedDateForDb =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const Gap(14),
            TextFormField(
              controller: _descriptionController,
              style: AppTheme.inputTextStyle(context),
              cursorColor: cs.primary,
              decoration: _dec('Descrição', icon: Icons.edit_note_rounded),
            ),
            const Gap(24),

            // ── Categorização ──────────────────────────────────────────
            _SectionLabel('Categorização'),
            const Gap(10),

            // Cartão
            cardsAsync.when(
              loading: () => _selectionField(
                label: 'Cartão',
                icon: Icons.credit_card_rounded,
                text: 'Carregando...',
                onTap: null,
              ),
              error: (_, __) => _selectionField(
                label: 'Cartão',
                icon: Icons.credit_card_rounded,
                text: 'Erro ao carregar',
                onTap: null,
              ),
              data: (cards) => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _selectionField(
                      label: 'Cartão',
                      icon: Icons.credit_card_rounded,
                      text: cards
                              .where((c) => c.id == _selectedCardId)
                              .firstOrNull
                              ?.name ??
                          'Nenhum (débito/dinheiro)',
                      onTap: () => _openCardPicker(cards),
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Material(
                      color: cs.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      child: InkWell(
                        onTap: _goToCardsAndRefresh,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                        child: Icon(
                          Icons.add_card_rounded,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(14),

            // Categoria
            categoriesAsync.when(
              loading: () => _selectionField(
                label: 'Categoria',
                icon: Icons.category_rounded,
                text: 'Carregando...',
                onTap: null,
              ),
              error: (_, __) => _selectionField(
                label: 'Categoria',
                icon: Icons.category_rounded,
                text: 'Erro ao carregar',
                onTap: null,
              ),
              data: (categories) {
                // Verifica se a categoria salva ainda existe
                final selectedExists =
                    categories.any((c) => c.id == _selectedCategoryId);
                return _selectionField(
                  label: 'Categoria',
                  icon: Icons.category_rounded,
                  text: selectedExists
                      ? categories
                              .where((c) => c.id == _selectedCategoryId)
                              .firstOrNull
                              ?.name ??
                          'Selecione'
                      : 'Selecione',
                  onTap: categories.isEmpty
                      ? null
                      : () => _openCategoryPicker(categories),
                );
              },
            ),
            const Gap(24),

            // ── Parcelamento (somente com cartão) ─────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _selectedCardId == null
                    ? const SizedBox.shrink(key: ValueKey('no_installments'))
                    : Column(
                        key: const ValueKey('with_installments'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Parcelamento'),
                          const Gap(6),
                          Text(
                            'Deixe em branco ou "1" para transação única.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(115),
                            ),
                          ),
                          const Gap(10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _installmentController,
                                  keyboardType: TextInputType.number,
                                  style: AppTheme.inputTextStyle(context),
                                  cursorColor: cs.primary,
                                  decoration: _decCompact('Nº parcelas'),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  validator: (v) {
                                    if (_selectedCardId == null) return null;
                                    if (v == null || v.isEmpty) return null;
                                    final n = int.tryParse(v);
                                    if (n != null && n < 1) return 'Mín. 1';
                                    return null;
                                  },
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: TextFormField(
                                  controller: _installmentCurrentController,
                                  keyboardType: TextInputType.number,
                                  style: AppTheme.inputTextStyle(context),
                                  cursorColor: cs.primary,
                                  decoration: _decCompact('Parcela atual'),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(24),
                        ],
                      ),
              ),
            ),
            const Gap(24),

            // ── Opções ─────────────────────────────────────────────────
            _SectionLabel('Opções'),
            const Gap(10),
            _OptionTile(
              icon: Icons.repeat_rounded,
              title: 'Recorrência mensal',
              subtitle: 'Repete automaticamente todo mês',
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            const Gap(14),

            // ── Nota ───────────────────────────────────────────────────
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              style: AppTheme.inputTextStyle(context),
              cursorColor: cs.primary,
              decoration:
                  _dec('Nota (opcional)', icon: Icons.sticky_note_2_rounded)
                      .copyWith(alignLabelWithHint: true),
            ),
            const Gap(32),

            // ── Botão salvar ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                ),
                onPressed: _save,
                child: Text(
                  widget.transaction != null
                      ? 'Atualizar transação'
                      : 'Salvar transação',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(115),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(102),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: cs.onSurface.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurface.withAlpha(140)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface)),
                Text(subtitle,
                    style: TextStyle(
                        color: cs.onSurface.withAlpha(140), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Modelo imutável de tipo de transação — só dados, sem lógica de UI.
class _TxType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _TxType(this.value, this.label, this.icon, this.color);
}

class _PickerChoice<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const _PickerChoice({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}
