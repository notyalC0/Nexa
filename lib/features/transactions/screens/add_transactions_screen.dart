import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
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

class _AddTransactionsScreenState
    extends ConsumerState<AddTransactionsScreen> {
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
    _TxType('expense', 'Despesa', Icons.arrow_downward_rounded,
        Colors.redAccent),
    _TxType('income', 'Receita', Icons.arrow_upward_rounded,
        Color(0xFF2ECC71)),
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
      _amountController.text =
          InputMasks.centsToCurrencyText(tx.amountCents);
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
    return List<int>.generate(
        safe, (i) => base + (i < remainder ? 1 : 0),
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
          const SnackBar(content: Text('Nenhuma categoria disponível.')),
        );
      }
      return;
    }

    final amount = InputMasks.currencyToCents(_amountController.text);
    final totalParcelas =
        int.tryParse(_installmentController.text.trim()) ?? 1;
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
      final baseDate =
          DateFormat('yyyy-MM-dd').parse(_selectedDateForDb!);
      final amounts = _splitAmount(amount, totalParcelas);

      for (int i = 0; i < totalParcelas; i++) {
        final parcelaDate = DateTime(
            baseDate.year, baseDate.month + i, baseDate.day);
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
        installmentGroupId: totalParcelas > 1
            ? widget.transaction?.installmentGroupId
            : null,
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
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: cs.onSurface.withAlpha(140))
          : null,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withAlpha(102),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide:
              BorderSide(color: cs.onSurface.withAlpha(77))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: cs.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: cs.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: cs.error, width: 1.8)),
      labelStyle:
          TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 14),
    );
  }

  /// Campo compacto (sem ícone, para uso lado a lado)
  InputDecoration _decCompact(String label) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withAlpha(102),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide:
              BorderSide(color: cs.onSurface.withAlpha(77))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: cs.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: cs.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          borderSide: BorderSide(color: cs.error, width: 1.8)),
      labelStyle:
          TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 13),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      isDense: true,
    );
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
              style: TextStyle(
                  color: cs.onSurface.withAlpha(140), fontSize: 14),
            ),
            const Gap(28),

            // ── Valor ──────────────────────────────────────────────────
            _SectionLabel('Valor'),
            const Gap(8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5),
              decoration: _dec('0,00').copyWith(
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withAlpha(140)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
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
                          color: isSelected
                              ? type.color
                              : Colors.transparent,
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
                  child: DropdownButtonFormField<String>(
                    decoration: _decCompact('Status'),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusChip),
                    isExpanded: true,
                    value: _selectedStatus,
                    onChanged: (v) => setState(() => _selectedStatus = v),
                    items: const [
                      DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pendente',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'confirmed',
                          child: Text('Confirmado',
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _decCompact('Data'),
                    readOnly: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a data' : null,
                    onTap: () async {
                      final initial = _selectedDateForDb != null
                          ? DateFormat('yyyy-MM-dd')
                              .parse(_selectedDateForDb!)
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
              decoration:
                  _dec('Descrição', icon: Icons.edit_note_rounded),
            ),
            const Gap(24),

            // ── Parcelamento ───────────────────────────────────────────
            _SectionLabel('Parcelamento'),
            const Gap(6),
            Text(
              'Deixe em branco ou "1" para transação única.',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withAlpha(115)),
            ),
            const Gap(10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _installmentController,
                    keyboardType: TextInputType.number,
                    decoration: _decCompact('Nº parcelas'),
                    // Só dígitos, máx 2 caracteres (até 99 parcelas)
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // opcional
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

            // ── Categorização ──────────────────────────────────────────
            _SectionLabel('Categorização'),
            const Gap(10),

            // Cartão
            cardsAsync.when(
              loading: () => DropdownButtonFormField<int>(
                decoration:
                    _dec('Cartão', icon: Icons.credit_card_rounded),
                onChanged: null,
                items: const [],
                hint: const Text('Carregando...'),
              ),
              error: (_, __) => DropdownButtonFormField<int>(
                decoration:
                    _dec('Cartão', icon: Icons.credit_card_rounded),
                onChanged: null,
                items: const [],
                hint: const Text('Erro ao carregar'),
              ),
              data: (cards) => DropdownButtonFormField<int>(
                decoration:
                    _dec('Cartão', icon: Icons.credit_card_rounded),
                value: _selectedCardId,
                onChanged: (v) => setState(() => _selectedCardId = v),
                hint: const Text('Nenhum (débito/dinheiro)'),
                items: [
                  // Opção "nenhum"
                  const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Nenhum (débito/dinheiro)')),
                  ...cards.map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.name))),
                ],
              ),
            ),
            const Gap(14),

            // Categoria
            categoriesAsync.when(
              loading: () => DropdownButtonFormField<int>(
                decoration:
                    _dec('Categoria', icon: Icons.category_rounded),
                onChanged: null,
                items: const [],
                hint: const Text('Carregando...'),
              ),
              error: (_, __) => DropdownButtonFormField<int>(
                decoration:
                    _dec('Categoria', icon: Icons.category_rounded),
                onChanged: null,
                items: const [],
                hint: const Text('Erro ao carregar'),
              ),
              data: (categories) {
                // Verifica se a categoria salva ainda existe
                final selectedExists = categories
                    .any((c) => c.id == _selectedCategoryId);
                return DropdownButtonFormField<int>(
                  decoration:
                      _dec('Categoria', icon: Icons.category_rounded),
                  value: selectedExists ? _selectedCategoryId : null,
                  onChanged: (v) =>
                      setState(() => _selectedCategoryId = v),
                  hint: const Text('Selecione'),
                  items: categories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                );
              },
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
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusChip),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        color: cs.onSurface.withAlpha(140), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: cs.primary,
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
