# Documentação Completa do Aplicativo Nexa

## Visão Geral

O **Nexa** é um aplicativo de controle financeiro pessoal desenvolvido em Flutter, projetado para ajudar usuários a gerenciar suas finanças de forma simples e intuitiva. O app permite o rastreamento de receitas, despesas, transações parceladas, recorrentes e integração com cartões de crédito, além de fornecer uma visão geral da saúde financeira através de uma pontuação calculada.

### Principais Funcionalidades

- **Dashboard Financeiro**: Exibe saldo disponível, receitas e despesas totais, com um indicador de saúde financeira.
- **Gerenciamento de Transações**: Adição, visualização e categorização de transações, incluindo suporte a parcelas e transações recorrentes.
- **Categorização**: Organização de transações em categorias personalizáveis (receitas e despesas) com ícones e cores.
- **Cartões de Crédito**: Integração para rastrear limites, datas de fechamento e vencimento.
- **Notificações**: Capacidade de criar transações a partir de notificações do sistema.
- **Temas**: Suporte a temas claro e escuro, com modo automático baseado no sistema.

## Arquitetura do Projeto

### Estrutura de Diretórios

```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart  # Gerenciamento do banco de dados SQLite
│   ├── models/
│   │   ├── categories.dart       # Modelo de dados para categorias
│   │   └── transactions.dart     # Modelo de dados para transações
│   ├── theme/
│   │   └── app_theme.dart        # Definições de tema da aplicação
│   ├── utils/                    # Utilitários diversos
│   └── widgets/                  # Widgets compartilhados
├── features/
│   ├── credit_card/              # Funcionalidades relacionadas a cartões (não implementado)
│   ├── emergency/                # Funcionalidades de emergência (não implementado)
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart  # Tela principal do aplicativo
│   │   └── widgets/
│   │       └── health_score_card.dart  # Widget da pontuação de saúde
│   ├── notifications/            # Funcionalidades de notificações (não implementado)
│   ├── settings/                 # Configurações do app (não implementado)
│   └── transactions/
│       ├── providers/
│       │   └── transactions_provider.dart  # Providers Riverpod para transações
│       ├── screens/
│       │   └── add_transactions_screen.dart  # Tela de adição de transações
│       └── widgets/
│           └── transaction_card.dart  # Widget para exibir transações
└── main.dart                     # Ponto de entrada da aplicação
```

### Tecnologias Utilizadas

- **Flutter**: Framework principal para desenvolvimento multiplataforma
- **Dart**: Linguagem de programação
- **Sqflite**: Banco de dados SQLite local
- **Riverpod**: Gerenciamento de estado reativo
- **FL Chart**: Biblioteca para gráficos (não utilizada ainda)
- **Intl**: Formatação de datas e números
- **Notification Listener Service**: Captura de notificações do sistema
- **Font Awesome Flutter**: Ícones
- **Flutter Animate**: Animações
- **Gap**: Espaçamento consistente

### Gerenciamento de Estado

O aplicativo utiliza **Riverpod** para gerenciamento de estado, com os seguintes providers principais:

- `categoriesProvider`: Fornece lista de categorias
- `selectedMonthProvider`: Controla o mês selecionado para filtrar transações
- `transactionsProvider`: Fornece transações filtradas por mês

### Banco de Dados

O banco de dados SQLite (`nexa.db`) contém as seguintes tabelas:

#### Tabela `categories`
- `id`: Chave primária autoincrementada
- `name`: Nome da categoria
- `icon`: Ícone associado (string)
- `color_hex`: Cor em formato hexadecimal
- `type`: Tipo ('income' ou 'expense')
- `is_default`: Se é uma categoria padrão

#### Tabela `credit_cards`
- `id`: Chave primária autoincrementada
- `name`: Nome do cartão
- `total_limit_cents`: Limite total em centavos
- `closing_day`: Dia de fechamento
- `due_day`: Dia de vencimento
- `color_hex`: Cor do cartão
- `bank_keyword`: Palavra-chave do banco para notificações

#### Tabela `transactions`
- `id`: Chave primária autoincrementada
- `amount_cents`: Valor em centavos
- `type`: Tipo da transação
- `status`: Status da transação
- `description`: Descrição opcional
- `date`: Data da transação (YYYY-MM-DD)
- `category_id`: ID da categoria (chave estrangeira)
- `credit_cards_id`: ID do cartão (opcional, chave estrangeira)
- `installment_total`: Número total de parcelas
- `installment_current`: Parcela atual
- `installment_group_id`: ID do grupo de parcelas
- `is_recurring`: Se é recorrente (0/1)
- `note`: Nota opcional
- `created_from_notification`: Se criada por notificação (0/1)
- `created_at`: Data de criação

#### Tabela `settings`
- `key`: Chave da configuração
- `value`: Valor da configuração
- `update_at`: Data de atualização

## Modelos de Dados

### Categories
Classe que representa uma categoria de transação, com métodos para conversão de/para Map.

### Transactions
Classe que representa uma transação financeira, suportando:
- Valores em centavos para precisão
- Parcelamento
- Transações recorrentes
- Criação via notificações

## Telas e Widgets

### HomeScreen
Tela principal que exibe:
- Header com saudação e saldo disponível
- Pilulas mostrando receitas e despesas
- Cartão de pontuação de saúde financeira
- Lista de transações recentes
- Botão flutuante para adicionar novas transações

### TransactionCard
Widget para exibir uma transação individual, mostrando valor, descrição, categoria e data.

### HealthScoreCard
Widget que exibe uma pontuação de saúde financeira (0-100) com indicador visual.

## Instalação e Execução

### Pré-requisitos
- Flutter SDK (>=2.19.6 <3.0.0)
- Dart SDK
- Android Studio ou VS Code com extensões Flutter
- Dispositivo/emulador para testes

### Passos para Instalação

1. **Clone o repositório**:
   ```bash
   git clone <url-do-repositorio>
   cd nexa
   ```

2. **Instale as dependências**:
   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo**:
   ```bash
   flutter run
   ```

### Build para Produção

**Android**:
```bash
flutter build apk --release
```

**iOS**:
```bash
flutter build ios --release
```

**Web**:
```bash
flutter build web --release
```

## Funcionalidades Implementadas

### ✅ Implementadas
- Estrutura básica do app com navegação
- Banco de dados local com Sqflite
- Modelos de dados para categorias e transações
- Tela inicial com dashboard financeiro
- Gerenciamento de estado com Riverpod
- Temas claro/escuro
- Suporte a parcelas em transações
- Criação de transações via notificações

### 🚧 Em Desenvolvimento
- Funcionalidades de cartões de crédito
- Sistema de notificações
- Configurações do usuário
- Funcionalidades de emergência

### 📋 Planejadas
- Gráficos e relatórios financeiros
- Sincronização com serviços externos
- Backup e restauração de dados
- Autenticação de usuário

## Contribuição

Para contribuir com o projeto:

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a MIT License - veja o arquivo LICENSE para detalhes.

## Suporte

Para suporte ou dúvidas, entre em contato através das issues do repositório.

---

**Última atualização**: 13 de março de 2026
**Versão**: 1.0.0+1</content>
<parameter name="filePath">c:\Dev\projetos\nexa\nexa\DOCUMENTATION.md
