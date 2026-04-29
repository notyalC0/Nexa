# Nexa 💳

Aplicativo de controle financeiro pessoal desenvolvido com Flutter, focado em simplicidade, design moderno e performance.

> **Versão atual:** 1.5.0
>
> Histórico completo: [CHANGELOG.md](CHANGELOG.md)

---

## Sumário

- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Tecnologias](#tecnologias)
- [Banco de dados](#banco-de-dados)
- [Temas e design](#temas-e-design)
- [Como rodar](#como-rodar)
- [Plataformas suportadas](#plataformas-suportadas)
- [Historico de Versoes](#historico-de-versoes)

---

## Funcionalidades

### Transações

- Cadastro de despesas, receitas e investimentos
- Separação entre **data da compra** (`purchase_date`) e **data efetiva no saldo** (`effective_date`)
- Suporte a transações **recorrentes** (geração automática mensal)
- **Desativação de recorrência** remove automaticamente todas as ocorrências futuras
- Suporte a **parcelamento** (divide o valor igualmente entre as parcelas, com distribuição justa de centavos)
- Status de transação: **Confirmado** ou **Pendente**
- Vinculação a **cartão de crédito** ou débito/dinheiro
- Vinculação a **categoria**
- Vinculação opcional a **meta financeira** (`goal_id`) para registrar aportes
- Campo de nota livre por transação
- **Badges visuais** no card: ícone + cor da categoria, nome + cor do cartão vinculado
- Seletor de data **sem entrada manual** (apenas date picker)
- Para cartão de crédito, a data efetiva é calculada automaticamente com base em **fechamento + vencimento**

### Lista de transações

- Filtro por **mês** com navegação por setas
- Chips de **filtro por tipo** (Todas, Despesas, Receitas, Investimentos)
- **Multi-seleção** com long press (1 segundo) + haptic feedback
- **Exclusão em lote** com confirmação
- **Swipe para deletar** (← arrasta) com painel vermelho revelado
- **Swipe para editar** (→ arrasta) com painel azul revelado
- **Animação de remoção** suave na lista (SliverAnimatedList)
- Checkbox animado por card em modo multi-seleção
- **Sincronização reativa**: a lista atualiza imediatamente ao editar dados (status, categoria, valor, recorrência)

### Análise e insights

- Tela dedicada de **análise financeira** com navegação mensal
- **Resumo do mês**: receitas, despesas e saldo em cards visuais
- **Gráfico de evolução** (BarChart): receitas vs despesas dos últimos 6 meses com tooltip interativo
- **Gastos por categoria**: top 6 do mês com ícone, cor, barra de progresso e percentual
- **Gastos por cartão de crédito**: split visual cartão vs débito/dinheiro + breakdown por cartão
- **Metas por categoria**: limites mensais por categoria com progresso e destaque quando o limite é ultrapassado
- **Orçamento mensal**: barra de progresso gasto vs salário configurado, com badge de status
- **Metas financeiras**: lista de metas ativas com progresso, valor restante e estimativa por média mensal de aportes
- **Atualização reativa**: dados recalculam automaticamente ao salvar/editar transações

### Metas

- Nova aba **Metas** na navegação principal
- Meta padrão de **Reserva de emergência** criada no banco como `is_default = true`
- Usuário pode criar metas com **nome, valor alvo, prazo opcional, ícone e cor**
- Cada aporte é uma **transação normal** que debita do saldo e preenche `goal_id`
- Metas possuem progresso calculado por: `initial_amount_cents + soma dos aportes confirmados`
- Estimativa de alcance baseada na **média mensal de aportes**
- A meta padrão de reserva **não pode ser deletada**

### Splash screen

- **Splash animada** com logo, nome do app e animações sequenciais (fade + scale)
- Transição suave para a tela principal
- Ao abrir o app pela primeira vez, exibe um modal com as novidades da versão

### Header / Home

- Exibe **saldo disponível**, com opção de ocultar
- Pills de resumo: **Receitas**, **Despesas**, **Projetado**
- Saudação dinâmica por horário (Bom dia / Boa tarde / Boa noite) com **nome do usuário**
- **Avatar do usuário** com foto personalizada (via galeria) ou iniciais
- Modo multi-seleção com **animações suaves** de transição (FAB, health card, header content)
- Header colapsável com **parallax**

### Score de saúde financeira

- Circular indicator animado com TweenAnimationBuilder
- Barras de progresso por categoria
- Aparece/desaparece com AnimatedSize ao entrar em modo de seleção

### Cartões de crédito

- Cadastro com nome, limite, dia de fechamento, dia de vencimento
- Cor e banco personalizáveis
- Exibe limite usado vs disponível

### Configurações

- **Perfil do usuário**: nome editável + avatar via galeria de fotos (`image_picker`)
- Toggle de visibilidade do saldo
- Tema claro/escuro
- Saldo inicial configurável
- Configuração de salário mensal
- Seção financeira orienta o uso da nova aba **Metas**
- Gerenciamento de categorias personalizadas com edição, exclusão e metas por categoria
- Metas por categoria com limite mensal e acompanhamento no Insights

### Notificações

- **Lembrete diário** configurável: notifica o usuário para registrar seus gastos
- Toggle on/off com solicitação de permissão em tempo real (Android 13+ / iOS)
- **Horário personalizável** via time picker (padrão: 20:00)
- Reagendamento automático ao reiniciar o app
- Reagendamento após reboot do dispositivo (Android)
- Usa `flutter_local_notifications` com `timezone` para precisão de fuso horário

---

## Arquitetura

O projeto segue uma arquitetura **Feature-first** com separação clara de responsabilidades:

```
feature/
  screens/   → widgets de tela (ConsumerWidget / ConsumerStatefulWidget)
  widgets/   → componentes reutilizáveis da feature
  providers/ → estado Riverpod (NotifierProvider, FutureProvider)
```

### Gerenciamento de estado

Utiliza **Riverpod 3** com `NotifierProvider` e `FutureProvider`:

| Provider                         | Tipo               | Responsabilidade                                                                        |
| -------------------------------- | ------------------ | --------------------------------------------------------------------------------------- |
| `balanceProvider`                | `FutureProvider`   | Saldo disponível, projetado, receitas, despesas                                         |
| `healthScoreProvider`            | `FutureProvider`   | Score de saúde financeira (0–100)                                                       |
| `transactionsByMonthProvider`    | `FutureProvider`   | Lista filtrada por mês/tipo                                                             |
| `transactionsProvider`           | `FutureProvider`   | Todas as transações do mês selecionado                                                  |
| `analyticsProvider`              | `FutureProvider`   | Dados completos de análise (trend, categorias, metas por categoria, cartões, orçamento) |
| `goalsProvider`                  | `FutureProvider`   | Lista de metas com progresso, restante e estimativa                                     |
| `categoryGoalsProvider`          | `FutureProvider`   | Metas por categoria com limite mensal e progresso                                       |
| `selectedMonthProvider`          | `StateProvider`    | Mês selecionado na tela de análise                                                      |
| `creditCardProvider`             | `FutureProvider`   | Lista de cartões                                                                        |
| `cardLimitDetailsProvider`       | `FutureProvider`   | Limites usados por cartão                                                               |
| `selectedTransactionIdsProvider` | `NotifierProvider` | Set de IDs em multi-seleção                                                             |
| `appSettingsProvider`            | `NotifierProvider` | Configurações (tema, saldo oculto, perfil, etc.)                                        |

### Otimizações de performance

- `.select()` em providers para rebuilds cirúrgicos (só rebuilda quando o dado relevante muda)
- `RepaintBoundary` por card (isolamento de repaint)
- `BouncingScrollPhysics` no scroll principal
- `_syncList` com diff de IDs + detecção de data-changes para o `SliverAnimatedList`
- `ref.read` em callbacks (sem watch em event handlers)
- `analyticsProvider` assiste `transactionsProvider` — atualiza automaticamente ao alterar transações
- Invalidação centralizada via `_invalidateAll()` (transações, saldo, score, analytics, metas)

---

## Estrutura de pastas

```
lib/
├── main.dart
├── core/
│   ├── database/
│   │   ├── database_helper.dart      # Singleton SQLite, migrações, CRUD
│   │   └── default_categories.dart   # Categorias padrão do app
│   ├── models/
│   │   ├── transactions.dart
│   │   ├── credit_cards.dart
│   │   ├── categories.dart
│   │   ├── goals.dart
│   │   ├── category_goal.dart
│   │   └── category_goal_progress.dart
│   ├── config/
│   │   └── app_config.dart
│   ├── notifications/
│   │   └── notification_service.dart # Singleton: agenda/cancela lembretes locais
│   ├── theme/
│   │   └── app_theme.dart            # Tokens visuais, helpers de estilo
│   ├── utils/
│   │   ├── currency_formatter.dart   # Formatação de centavos → R$ X.XXX,XX
│   │   └── input_masks.dart          # Máscara de moeda + conversão
│   └── widgets/
│       ├── app_shimmer.dart          # Skeleton loading
│       └── app_empty_state.dart      # Estado vazio genérico
│
└── features/
    ├── home/
    │   ├── screens/home_screen.dart
    │   ├── provider/
    │   │   ├── balance_provider.dart
    │   │   └── health_score_provider.dart
    │   └── widgets/
    │       ├── balance_pill.dart
    │       └── health_score_card.dart
    ├── transactions/
    │   ├── screens/
    │   │   ├── transactions_screen.dart      # Lista + filtros + SliverAnimatedList
    │   │   └── add_transactions_screen.dart  # Formulário criar/editar
    │   ├── widgets/
    │   │   ├── transaction_card.dart         # Card com swipe, long-press, seleção
    │   │   └── transaction_filter_bar.dart   # Barra de filtro sticky
    │   └── providers/
    │       ├── transactions_provider.dart
    │       ├── transactions_filter_provider.dart
    │       └── transactions_selection_provider.dart
    ├── insights/
    │   ├── screens/insights_screen.dart      # Tela completa de análise financeira
    │   └── providers/analytics_provider.dart # Trend, categorias, metas por categoria, cartões, orçamento e metas
    ├── goals/
    │   ├── models/goal_progress.dart
    │   ├── providers/goals_provider.dart
    │   └── screens/goals_screen.dart
    ├── splash/
    │   └── screens/splash_screen.dart        # Splash animada com logo
    ├── cards/
    │   ├── screens/card_screen.dart
    │   └── providers/cards_provider.dart
    └── settings/
        ├── screens/settings_screen.dart
        ├── screens/category_management_screen.dart
        └── providers/app_settings_provider.dart
```

---

## Tecnologias

| Pacote                        | Versão  | Uso                                               |
| ----------------------------- | ------- | ------------------------------------------------- |
| `flutter_riverpod`            | ^3.3.1  | Gerenciamento de estado                           |
| `sqflite`                     | ^2.4.2  | Banco de dados SQLite (mobile)                    |
| `sqflite_common_ffi`          | ^2.3.4  | SQLite via FFI (Windows, Linux, macOS)            |
| `path`                        | ^1.9.1  | Resolução de caminhos de arquivo                  |
| `intl`                        | ^0.20.2 | Formatação de datas                               |
| `mask_text_input_formatter`   | ^2.9.0  | Máscara de input monetário                        |
| `uuid`                        | ^4.5.3  | IDs únicos para grupos de parcelas e recorrências |
| `gap`                         | ^3.0.1  | Espaçamento semântico                             |
| `fl_chart`                    | ^1.1.1  | Gráficos (health score, análise de tendência)     |
| `image_picker`                | ^1.1.2  | Seleção de foto do avatar do usuário              |
| `google_fonts`                | ^6.2.1  | Tipografia                                        |
| `flutter_native_splash`       | ^2.4.7  | Splash screen nativa                              |
| `flutter_local_notifications` | ^18.0.1 | Notificações locais agendadas (Android/iOS)       |
| `timezone`                    | ^0.9.4  | Fusos horários para agendamento preciso           |
| `flutter_timezone`            | ^5.0.2  | Detecta o fuso horário local do dispositivo       |

---

## Banco de dados

SQLite gerenciado por `DatabaseHelper` (singleton). Schema versão 5.

### Tabelas

**`transactions`**
| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `amount_cents` | INTEGER | Valor em centavos |
| `type` | TEXT | `expense`, `income`, `investment` |
| `status` | TEXT | `confirmed`, `pending` |
| `description` | TEXT | Descrição livre |
| `purchase_date` | TEXT | Data da compra / lançamento (`yyyy-MM-dd`) |
| `effective_date` | TEXT | Data em que impacta o saldo (`yyyy-MM-dd`) |
| `category_id` | INTEGER FK | Categoria |
| `credit_cards_id` | INTEGER FK | Cartão (nullable) |
| `is_invoice_paid` | INTEGER | `0/1`, nullable para não-cartão e legado |
| `goal_id` | INTEGER FK | Meta vinculada (nullable) |
| `is_recurring` | INTEGER | 0/1 |
| `recurring_id` | TEXT | UUID do grupo recorrente |
| `parent_id` | INTEGER | ID da transação pai |
| `installment_total` | INTEGER | Total de parcelas |
| `installment_current` | INTEGER | Número da parcela atual |
| `installment_group_id` | TEXT | UUID do grupo de parcelas |
| `note` | TEXT | Nota livre |
| `created_at` | TEXT | Timestamp de criação |

**`credit_cards`** — `id`, `name`, `total_limit_cents`, `closing_day`, `due_day`, `color_hex`, `bank_keyword`

**`categories`** — `id`, `name`, `icon`, `color_hex`, `type`, `is_default`

**`goals`** — `id`, `name`, `target_amount_cents`, `initial_amount_cents`, `target_date`, `icon`, `color_hex`, `is_default`, `is_deletable`, `is_archived`, `created_at`, `updated_at`

**`category_goals`** — `id`, `category_id`, `limit_cents`

**`settings`** — `key`, `value` (chave-valor genérico)

### Migrações

- **v1 → v2**: remove categorias duplicadas, cria índices
- **v2 → v3**: adiciona `recurring_id`, `parent_id`, migra transações recorrentes existentes
- **v3 → v4**:
  - substitui `date` por `purchase_date` + `effective_date`
  - adiciona `is_invoice_paid` e `goal_id` em `transactions`
  - cria a tabela `goals`
  - migra a reserva de emergência antiga de `settings` para uma meta padrão
- **v4 → v5**:
  - cria a tabela `category_goals` para limites mensais por categoria
  - mantém a integridade dos relacionamentos com `categories`

---

## Temas e design

Tokens centralizados em `AppTheme`:

| Token           | Valor |
| --------------- | ----- |
| `radiusCard`    | 16    |
| `radiusChip`    | 8     |
| `radiusModal`   | 24    |
| `paddingScreen` | 20    |
| `paddingCard`   | 16    |

Helpers estáticos de estilo: `titleStyle`, `subtitleStyle`, `metaStyle`, `actionStyle`, `inputDecoration`, `snackBar`.

Suporta **tema claro e escuro** via `ThemeMode` configurável pelo usuário.

---

## Como rodar

### Pré-requisitos

- Flutter SDK ≥ 3.38.4
- Dart SDK ≥ 3.10.3

### Instalação

```bash
git clone https://github.com/notyalC0/Nexa.git
cd Nexa
flutter pub get
flutter run
```

### Desktop (Windows / Linux / macOS)

O app suporta desktop via `sqflite_common_ffi`. Não é necessária nenhuma configuração adicional — a inicialização é feita automaticamente em `main.dart`:

```dart
if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

Para rodar no Windows:

```bash
flutter run -d windows
```

### Notificações (Android)

O app usa `core library desugaring` para compatibilidade com APIs Java 8+ em dispositivos mais antigos. Isso já está configurado em `android/app/build.gradle.kts`.

As permissões `POST_NOTIFICATIONS`, `VIBRATE` e `RECEIVE_BOOT_COMPLETED` são declaradas no `AndroidManifest.xml`. A permissão de notificação é solicitada ao usuário no momento em que ele ativa o toggle em **Configurações → Notificações**.

---

## Plataformas suportadas

| Plataforma | Status                                   |
| ---------- | ---------------------------------------- |
| Android    | ✅ Suportado                             |
| iOS        | ✅ Suportado                             |
| Windows    | ✅ Suportado (FFI)                       |
| Linux      | ✅ Suportado (FFI)                       |
| macOS      | ✅ Suportado (FFI)                       |
| Web        | ⚠️ Não suportado (SQLite não disponível) |

---

## Historico de Versoes

O histórico detalhado de mudanças foi movido para [CHANGELOG.md](CHANGELOG.md).
