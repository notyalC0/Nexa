import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/notifications/notification_service.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/utils/input_masks.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/goals/providers/goals_provider.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/insights/providers/analytics_provider.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/settings/widgets/settings_widget.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _sheetHandle(ColorScheme cs) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cs.onSurface.withAlpha(38),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  // ─── Dialogs e Sheets ────────────────────────────────────────────────────

  void _showAboutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Lista padronizada para facilitar atualizações futuras
    final List<Map<String, dynamic>> changelogs = [
      {
        'version': '1.4.0',
        'title': 'Metas & Lógica',
        'items': [
          'Nova aba dedicada de Metas Financeiras',
          'Saldo real por competência (Data compra vs impacto)',
          'Cálculo automático de ciclo de cartão de crédito',
          'Schema de banco de dados atualizado para v4'
        ]
      },
      {
        'version': '1.3.0',
        'title': 'Análise & UX',
        'items': [
          'Dashboard analítico com gráficos de evolução',
          'Perfil editável com avatares da galeria',
          'Nova Splash Screen e animações de entrada',
          'Badges visuais para categorias e cartões'
        ]
      },
      {
        'version': '1.1.0',
        'title': 'Base & Estabilidade',
        'items': [
          'Automação de transações recorrentes mensais',
          'Lógica de limites dinâmicos para cartões',
          'Gestão de categorias com fallback automático',
          'Otimização de performance com Riverpod'
        ]
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do App
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.primary.withAlpha(204)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                        color: cs.onPrimary, size: 32),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nexa',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface)),
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withAlpha(20),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(color: cs.primary.withAlpha(38)),
                          ),
                          child: Text(
                            'Versão 1.4.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(20),

              // Card de Descrição
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(90),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: cs.onSurface.withAlpha(20)),
                ),
                child: Text(
                  'Controle financeiro pessoal simples e eficiente.',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.4),
                ),
              ),

              const Gap(24),
              Text('O que há de novo',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const Gap(12),

              // Seção de Novidades com Scroll Dinâmico
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: changelogs
                          .map((log) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(log['version'],
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: cs.primary)),
                                        const Gap(8),
                                        Text(log['title'],
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: cs.onSurface
                                                    .withAlpha(180))),
                                      ],
                                    ),
                                    const Gap(8),
                                    ...List.generate(
                                        log['items'].length,
                                        (i) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4, bottom: 4),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 6),
                                                    child: Icon(Icons.circle,
                                                        size: 4,
                                                        color: cs.primary),
                                                  ),
                                                  const Gap(10),
                                                  Expanded(
                                                    child: Text(log['items'][i],
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: cs.onSurface
                                                                .withAlpha(160),
                                                            height: 1.3)),
                                                  ),
                                                ],
                                              ),
                                            )),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Sheet para inserir valores monetários (salário, reserva, etc.)
  ///
  /// CORREÇÃO: agora usa Form + validator, então não salva valor zero
  /// por acidente se o usuário não preencher nada.
  void _showFinancialSheet(
    BuildContext context,
    WidgetRef ref,
    String key,
    String title,
    int initialCents,
  ) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(
      text:
          initialCents > 0 ? InputMasks.centsToCurrencyText(initialCents) : '',
    );
    final currencyMask = InputMasks.currency();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                _sheetHandle(cs),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                ),
                const Gap(6),
                Text(
                  'Digite um valor',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withAlpha(153),
                    height: 1.45,
                  ),
                ),
                const Gap(16),
                TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [currencyMask],
                  autofocus: true,
                  style: AppTheme.inputTextStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: cs.primary,
                  decoration: AppTheme.inputDecoration(
                    context,
                    label: 'Valor',
                    prefixText: 'R\$ ',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe um valor';
                    if (InputMasks.currencyToCents(v) <= 0) {
                      return 'O valor deve ser maior que zero';
                    }
                    return null;
                  },
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusChip)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final cents = InputMasks.currencyToCents(controller.text);
                      await ref
                          .read(appSettingsProvider.notifier)
                          .saveMoneySetting(key, cents);
                      ref.invalidate(healthScoreProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Salvar',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showManageCategoriesDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Icon(Icons.category_rounded, color: cs.primary, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nova categoria',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const Gap(2),
                  Text(
                    'Crie uma categoria personalizada para suas transações.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            style: AppTheme.inputTextStyle(context),
            cursorColor: cs.primary,
            decoration: AppTheme.inputDecoration(
              context,
              label: 'Nome da categoria',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe o nome da categoria';
              }
              if (v.trim().length < 2) {
                return 'Nome muito curto (mín. 2 caracteres)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface.withAlpha(178),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = controller.text.trim();
              final existing = await DatabaseHelper.instance.getCategories();

              // Verifica duplicata (case-insensitive)
              final alreadyExists = existing.any(
                (c) => c.name.toLowerCase() == name.toLowerCase(),
              );

              if (alreadyExists) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.snackBar(
                      context,
                      message: 'A categoria "$name" já existe.',
                      icon: Icons.info_outline_rounded,
                    ),
                  );
                }
                return;
              }

              await DatabaseHelper.instance.insertCategory(
                Categories(
                  name: name,
                  icon: 'label',
                  colorHex: '#5B5F97',
                  type: 'expense',
                ),
              );

              ref.invalidate(categoriesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.snackBar(
                    context,
                    message: 'Categoria "$name" adicionada com sucesso!',
                    icon: Icons.check_circle_outline_rounded,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF133223)
                            : const Color(0xFF166534),
                    foregroundColor: Colors.white,
                  ),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirm(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.error.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Apagar dados',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ),
        ]),
        content: Text(
          'Todos os dados serão removidos permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(
              fontSize: 14, color: cs.onSurface.withAlpha(178), height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withAlpha(153)),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              // Invalida todos os providers para resetar o estado da UI
              ref
                ..invalidate(categoriesProvider)
                ..invalidate(transactionsProvider)
                ..invalidate(transactionsByMonthProvider)
                ..invalidate(creditCardProvider)
                ..invalidate(balanceProvider)
                ..invalidate(healthScoreProvider)
                ..invalidate(goalsProvider)
                ..invalidate(defaultGoalProgressProvider)
                ..invalidate(analyticsProvider)
                ..invalidate(appSettingsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            ),
            child: const Text('Apagar tudo',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Time Picker para horário do lembrete ────────────────────────────────

  Future<void> _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked == null) return;

    // Salva e reagenda
    await ref
        .read(appSettingsProvider.notifier)
        .saveReminderTime(picked.hour, picked.minute);

    await NotificationService.instance.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (settings) => Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: Text(
            'Configurações',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingScreen, 8, AppTheme.paddingScreen, 40),
          children: [
            // ── Perfil ──────────────────────────────────────────────
            const _ProfileCard(),
            const Gap(24),

            // ── Finanças ────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Finanças'),
            const Gap(10),
            SettingsTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Salário mensal',
              subtitle: settings.salaryCents == 0
                  ? 'Não configurado'
                  : CurrencyFormatter.format(settings.salaryCents),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showFinancialSheet(
                context,
                ref,
                'monthly_salary_cents',
                'Salário mensal',
                settings.salaryCents,
              ),
            ),
            SettingsTile(
              icon: Icons.flag_rounded,
              title: 'Metas financeiras',
              subtitle: 'Crie e acompanhe metas na aba Metas',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withAlpha(89),
              ),
              onTap: null,
            ),
            const Gap(24),

            // ── Aparência ────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Aparência'),
            const Gap(10),
            SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Modo escuro',
              subtitle: 'Ativar tema escuro no app',
              trailing: Switch(
                value: settings.darkMode,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .saveBoolSetting('dark_mode', v),
              ),
            ),
            const Gap(24),

            // ── Notificações (apenas Android/iOS) ────────────────────
            if (NotificationService.instance.isSupported) ...[
              const SettingsSectionHeader(label: 'Notificações'),
              const Gap(10),
              SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notificações',
                subtitle: 'Alertas diários para registrar seus gastos',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (v) async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .saveBoolSetting('notifications_enabled', v);
                    if (v) {
                      final granted = await NotificationService.instance
                          .requestPermissions();
                      if (granted) {
                        await NotificationService.instance
                            .scheduleDailyReminder(
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppTheme.snackBar(
                            context,
                            message:
                                'Permissão negada. Habilite nas configurações do sistema.',
                            icon: Icons.notifications_off_rounded,
                          ),
                        );
                      }
                    } else {
                      await NotificationService.instance.cancelDailyReminder();
                    }
                  },
                ),
              ),
              if (settings.notificationsEnabled) ...[
                const Gap(2),
                SettingsTile(
                  icon: Icons.access_time_rounded,
                  title: 'Horário do lembrete',
                  subtitle:
                      'Diariamente às ${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}',
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: cs.onSurface.withAlpha(89)),
                  onTap: () => _showTimePicker(context, ref, settings),
                ),
              ],
              const Gap(24),
            ], // if (NotificationService.instance.isSupported)

            // ── Categorias ────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Categorias'),
            const Gap(10),
            SettingsTile(
              icon: Icons.category_rounded,
              title: 'Adicionar categoria',
              subtitle: 'Crie categorias personalizadas para transações',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showManageCategoriesDialog(context, ref),
            ),
            const Gap(24),

            // ── Dados ─────────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Dados'),
            const Gap(10),
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Apagar todos os dados',
              subtitle: 'Remove todas as transações e cartões',
              iconColor: cs.error,
              titleColor: cs.error,
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.error.withAlpha(127)),
              onTap: () => _showClearDataConfirm(context, ref),
            ),
            const Gap(24),

            // ── Sobre ──────────────────────────────────────────────────
            const SettingsSectionHeader(label: 'Sobre'),
            const Gap(10),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o Nexa',
              subtitle: 'Versão 1.4.0',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(89)),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard();

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  bool _editing = false;
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref
        .read(appSettingsProvider.notifier)
        .saveStringSetting('user_avatar_path', picked.path);
  }

  Future<void> _saveName(String name) async {
    final trimmed = name.trim();
    await ref
        .read(appSettingsProvider.notifier)
        .saveStringSetting('user_name', trimmed);
    setState(() => _editing = false);
  }

  void _startEditing(String current) {
    _nameController.text = current;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(appSettingsProvider).asData?.value;
    final userName = settings?.userName ?? '';
    final avatarPath = settings?.userAvatarPath;

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          // Avatar tappable
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarPath != null && File(avatarPath).existsSync()
                      ? Image.file(File(avatarPath), fit: BoxFit.cover)
                      : Icon(Icons.person_rounded,
                          color: cs.onPrimary, size: 30),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: cs.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 12, color: cs.primary),
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          Expanded(
            child: _editing
                ? TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimary),
                    cursorColor: cs.onPrimary,
                    decoration: InputDecoration(
                      hintText: 'Seu nome',
                      hintStyle: TextStyle(color: cs.onPrimary.withAlpha(140)),
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: cs.onPrimary.withAlpha(120)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cs.onPrimary),
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: _saveName,
                  )
                : GestureDetector(
                    onTap: () => _startEditing(userName),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName.isEmpty
                                    ? 'Toque para definir seu nome'
                                    : userName,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: userName.isEmpty
                                        ? cs.onPrimary.withAlpha(140)
                                        : cs.onPrimary),
                              ),
                            ),
                            Icon(Icons.edit_rounded,
                                size: 14, color: cs.onPrimary.withAlpha(166)),
                          ],
                        ),
                        Text('Conta pessoal',
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onPrimary.withAlpha(166))),
                      ],
                    ),
                  ),
          ),
          // Botão salvar nome (visível só no modo edição)
          if (_editing) ...[
            const Gap(8),
            GestureDetector(
              onTap: () => _saveName(_nameController.text),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withAlpha(28),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  'Salvar',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
