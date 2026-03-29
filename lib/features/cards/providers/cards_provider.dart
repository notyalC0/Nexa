import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/models/credit_cards.dart';
import '../../../core/database/database_helper.dart';

/// Dados de limite de um cartão no ciclo de faturamento atual.
class CardLimitDetails {
  final int usedCents;
  final int dynamicLimitCents;

  const CardLimitDetails({
    required this.usedCents,
    required this.dynamicLimitCents,
  });

  /// Quanto ainda está disponível (nunca negativo)
  int get availableCents =>
      (dynamicLimitCents - usedCents).clamp(0, dynamicLimitCents);

  /// Percentual de uso entre 0.0 e 1.0
  double get usedPercent =>
      dynamicLimitCents == 0 ? 0 : (usedCents / dynamicLimitCents).clamp(0.0, 1.0);
}

/// Lista todos os cartões cadastrados.
final creditCardProvider = FutureProvider<List<CreditCards>>((ref) async {
  return DatabaseHelper.instance.getCreditCards();
});

/// Detalhes de limite de UM cartão específico pelo seu ID.
///
/// CORREÇÃO DE PERFORMANCE:
/// O código anterior buscava TODOS os cartões (creditCardProvider) só para
/// pegar o totalLimitCents de um cartão específico. Isso significa que ao
/// exibir 3 cartões, buscávamos a lista 3 vezes.
///
/// Agora o DatabaseHelper já recebe o cardId no getCardUsedLimit (que busca
/// o cartão internamente para calcular o ciclo) e nós buscamos o limite
/// total diretamente por ID — uma query só.
///
/// Por que FutureProvider.family?
/// Porque cada cartão tem um ID diferente. O family cria uma instância
/// separada do provider para cada ID, então cartão 1 e cartão 2 têm
/// caches independentes.
final cardLimitDetailsProvider =
    FutureProvider.family<CardLimitDetails, int>((ref, cardId) async {
  final db = DatabaseHelper.instance;

  // Busca em paralelo: limite usado no ciclo atual + dados do cartão
  // Future.wait executa as duas queries ao mesmo tempo em vez de sequencial
  final results = await Future.wait([
    db.getCardUsedLimit(cardId),          // usa o ciclo de faturamento correto
    db.getCreditCardById(cardId),          // ver nota abaixo
  ]);

  final usedCents = results[0] as int;
  final card = results[1] as CreditCards?;

  return CardLimitDetails(
    usedCents: usedCents,
    dynamicLimitCents: card?.totalLimitCents ?? 0,
  );
});
