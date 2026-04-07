import 'package:flutter/material.dart';

/// Lightweight compile-time translations for English and Russian.
///
/// Usage in ConsumerWidget:
///   ```dart
///   final s = ref.watch(stringsProvider); // from locale_provider.dart
///   Text(s.send)
///   ```
class S {
  final Locale locale;
  const S(this.locale);

  bool get _ru => locale.languageCode == 'ru';

  // ── App bar / navigation ────────────────────────────────────────────────
  String get appTitle => _ru ? 'VAVEL КОШЕЛЁК' : 'VAVEL WALLET';
  String get settings => _ru ? 'Настройки' : 'Settings';
  String get lockWallet => _ru ? 'Заблокировать' : 'Lock wallet';

  // ── Dashboard ───────────────────────────────────────────────────────────
  String get totalPortfolio => _ru ? 'Мой портфель' : 'Total Portfolio';
  String get usdValue => _ru ? 'Стоимость в USD' : 'USD Value';
  String get balancesUnavailable =>
      _ru ? 'Некоторые балансы недоступны' : 'Some balances unavailable';

  // ── Asset actions ───────────────────────────────────────────────────────
  String get send => _ru ? 'Отправить' : 'Send';
  String get receive => _ru ? 'Получить' : 'Receive';
  String get swap => _ru ? 'Обмен' : 'Swap';

  // ── Price ───────────────────────────────────────────────────────────────
  String get priceLoading => _ru ? 'Загрузка цен…' : 'Loading prices…';
  String get priceUnavailable => _ru ? 'Цена недоступна' : 'Price unavailable';

  // ── Settings ────────────────────────────────────────────────────────────
  String get language => _ru ? 'Язык' : 'Language';
  String get langEnglish => 'English';
  String get langRussian => 'Русский';

  // ── Network ─────────────────────────────────────────────────────────────
  String get network => _ru ? 'Сеть' : 'Network';
  String get networkMainnet => _ru ? 'Mainnet (боевая сеть)' : 'Mainnet (Live)';
  String get networkTestnet =>
      _ru ? 'Testnet (тестовая сеть)' : 'Testnet (Test only)';
  String get networkMainnetDesc =>
      _ru ? 'Реальные транзакции и балансы' : 'Real transactions & balances';
  String get networkTestnetDesc => _ru
      ? 'Devnet/Sepolia/Testnet3 — без реальных средств'
      : 'Devnet / Sepolia / Testnet3 — no real funds';
  String get networkTestnetWarning => _ru
      ? '⚠ Тестовая сеть активна — реальные средства недоступны'
      : '⚠ Testnet active — real funds are not accessible';

  // ── RPC error hints ──────────────────────────────────────────────────────
  String get rpcKeyHintEth =>
      '--dart-define=ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY';
  String get rpcKeyHintSol =>
      '--dart-define=SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY';
  String get rpcKeyHintTon => '--dart-define=TONCENTER_API_KEY=YOUR_KEY';

  // ── Swap screen ─────────────────────────────────────────────────────────
  String get swapTitle => _ru ? 'Конвертация' : 'Swap / Convert';
  String get swapFrom => _ru ? 'Из' : 'From';
  String get swapTo => _ru ? 'В' : 'To';
  String get swapAmount => _ru ? 'Сумма' : 'Amount';
  String get swapResult => _ru ? 'Вы получите' : 'You receive';
  String get swapRate => _ru ? 'Курс' : 'Rate';
  String get swapNote => _ru
      ? 'Расчёт основан на текущих рыночных ценах. Реальный обмен происходит через DEX.'
      : 'Estimate based on live market prices. Actual swap requires a DEX.';
  String get swapPricesMissing =>
      _ru ? 'Цены ещё не загружены.' : 'Prices not yet loaded.';

  // ── Send screen ─────────────────────────────────────────────────────────
  String get sendTitle => _ru ? 'Отправить' : 'Send';
  String get recipientAddress => _ru ? 'Адрес получателя' : 'Recipient address';
  String get amountLabel => _ru ? 'Количество' : 'Amount';
  String get maxBalance => _ru ? 'MAX' : 'MAX';
  String get confirmSend => _ru ? 'Подтвердить отправку' : 'Confirm send';

  // ── Receive screen ──────────────────────────────────────────────────────
  String get receiveTitle => _ru ? 'Получить' : 'Receive';
  String get yourAddress => _ru ? 'Ваш адрес' : 'Your address';
  String get copyAddress => _ru ? 'Скопировать' : 'Copy address';
  String get addressCopied => _ru ? 'Адрес скопирован' : 'Address copied';
}
