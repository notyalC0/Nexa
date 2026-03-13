import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import '../../../core/models/transactions.dart';

class AddTransactionsScreen extends ConsumerStatefulWidget {
  const AddTransactionsScreen({super.key});

  @override
  ConsumerState<AddTransactionsScreen> createState() =>
      _AddTransactionsScreenState();
}

class _AddTransactionsScreenState extends ConsumerState<AddTransactionsScreen> {
  bool _isRecurring = false;
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedDateForDb; // yyyy-MM-dd — formato para o banco
  bool _triedToSave = false;

  final _types = [
    _TransactionType('expense', 'Despesa', Icons.arrow_downward_rounded, Colors.redAccent),
    _TransactionType('income', 'Receita', Icons.arrow_upward_rounded, Color(0xFF2ECC71)),
    _TransactionType('investment', 'Investimento', Icons.trending_up_rounded, Colors.blueAccent),
  ];

  // Decoração COMPACTA — sem ícone, para campos usados lado a lado (~half screen)
  InputDecoration _fieldDecorationCompact(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.8),
      ),
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      isDense: true,
    );
  }

  // Decoração NORMAL — com ícone, para campos em largura total
  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))
          : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.8),
      ),
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
    );
  }

  void _saveTransaction() {
    setState(() => _triedToSave = true);
    if (_selectedType == null) return;
    if (_formKey.currentState!.validate()) {
      final amount =
          (double.parse(_amountController.text.replaceAll(',', '.')) * 100).toInt();

      final transaction = Transactions(
        amountCents: amount,
        type: _selectedType!,
        status: _selectedStatus ?? 'confirmed', // nullable — sem !
        description: _descriptionController.text,
        date: _selectedDateForDb ?? _dateController.text, // formato yyyy-MM-dd
        categoryID: 1,
        isRecurring: _isRecurring,
        createdFromNotification: false,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      DatabaseHelper.instance.insertTransaction(transaction);
      ref.invalidate(transactionsProvider);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
            AppTheme.paddingScreen,
            0,
            AppTheme.paddingScreen,
            40,
          ),
          children: [
            // --- Cabeçalho ---
            Text(
              'Nova Transação',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            Text(
              'Preencha os dados abaixo',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
            ),
            const Gap(28),

            // --- Valor ---
            // prefixText (String) ao invés de prefix (Widget) evita o overflow
            // do Row interno do InputDecorator com fontes grandes
            _SectionLabel(label: 'Valor'),
            const Gap(8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              decoration: _fieldDecoration('0,00').copyWith(
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe um valor';
                if (double.tryParse(value.replaceAll(',', '.')) == null) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const Gap(24),

            // --- Tipo ---
            _SectionLabel(label: 'Tipo'),
            const Gap(10),
            Row(
              children: _types.map((type) {
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
                        right: type != _types.last ? 10 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type.color.withOpacity(0.15)
                            : colorScheme.surfaceVariant.withOpacity(0.4),
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
                            textAlign: TextAlign.center,
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
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const Gap(24),

            // --- Detalhes: Status + Data lado a lado ---
            // crossAxisAlignment.start é obrigatório para que as mensagens
            // de erro sob cada campo não forcem overflow vertical no Row
            _SectionLabel(label: 'Detalhes'),
            const Gap(10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _fieldDecorationCompact('Status'),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    isExpanded: true,
                    validator: null,
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text(
                          'Pendente',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text(
                          'Confirmado',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _fieldDecorationCompact('Data'),
                    readOnly: true,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Informe' : null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        // exibição legível para o usuário
                        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        // formato ISO para persistência no SQLite
                        _selectedDateForDb = DateFormat('yyyy-MM-dd').format(picked);
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
                  _fieldDecoration('Descrição', icon: Icons.edit_note_rounded),
            ),
            const Gap(24),

            // --- Parcelamento ---
            _SectionLabel(label: 'Parcelamento'),
            const Gap(10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecorationCompact('Nº parcelas'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecorationCompact('Parcela atual'),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // --- Categorização ---
            _SectionLabel(label: 'Categorização'),
            const Gap(10),
            DropdownButtonFormField<String>(
              decoration:
                  _fieldDecoration('Cartão', icon: Icons.credit_card_rounded),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              onChanged: (_) {},
              items: const [],
              hint: const Text('Nenhum cartão'),
            ),
            const Gap(14),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration:
                  _fieldDecoration('Categoria', icon: Icons.category_rounded),
            ),
            const Gap(24),

            // --- Opções ---
            _SectionLabel(label: 'Opções'),
            const Gap(10),
            _OptionTile(
              icon: Icons.repeat_rounded,
              title: 'Recorrência mensal',
              subtitle: 'Repete automaticamente todo mês',
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            const Gap(14),

            // --- Nota ---
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: _fieldDecoration(
                'Nota (opcional)',
                icon: Icons.sticky_note_2_rounded,
              ).copyWith(alignLabelWithHint: true),
            ),
            const Gap(32),

            // --- Salvar ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                ),
                onPressed: _saveTransaction,
                child: const Text(
                  'Salvar transação',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _TransactionType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _TransactionType(this.value, this.label, this.icon, this.color);
}
