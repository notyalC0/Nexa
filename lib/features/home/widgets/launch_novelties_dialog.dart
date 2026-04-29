import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/theme/app_theme.dart';

Future<void> showLaunchNoveltiesDialog(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusModal),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.primary.withAlpha(214)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: cs.onPrimary.withAlpha(28),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: cs.onPrimary,
                            size: 28,
                          ),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Novidades do Nexa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onPrimary,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'Tudo o que mudou nesta versão, em um resumo rápido.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: cs.onPrimary.withAlpha(220),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: cs.primary.withAlpha(34)),
                      ),
                      child: Text(
                        'Versão 1.5.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  _HighlightItem(
                    icon: Icons.category_rounded,
                    color: cs.primary,
                    title: 'Categorias com metas',
                    subtitle:
                        'Você pode gerenciar categorias e definir limites mensais por categoria.',
                  ),
                  const Gap(10),
                  _HighlightItem(
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF2ECC71),
                    title: 'Insights mais completos',
                    subtitle:
                        'A análise agora mostra progresso e alerta quando a meta é ultrapassada.',
                  ),
                  const Gap(10),
                  _HighlightItem(
                    icon: Icons.storage_rounded,
                    color: const Color(0xFF6C8EFF),
                    title: 'Banco atualizado',
                    subtitle:
                        'O schema foi para a versão 5 para suportar as metas por categoria.',
                  ),
                  const Gap(16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(90),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: cs.onSurface.withAlpha(16)),
                    ),
                    child: Text(
                      'Depois você encontra o histórico detalhado em Sobre e continua com a navegação normal.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                  const Gap(18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                      onPressed: () async {
                        await DatabaseHelper.instance.saveSetting(
                          'launch_novelties_seen',
                          '1',
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text(
                        'Começar a usar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HighlightItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _HighlightItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cs.onSurface.withAlpha(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: cs.onSurface.withAlpha(170),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
