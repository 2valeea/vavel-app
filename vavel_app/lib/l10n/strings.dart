import 'package:flutter/material.dart';

/// Lightweight compile-time translations.
///
/// Supported locales: en, ru, de, da, et, pt, uk.
///
/// Usage in ConsumerWidget:
///   ```dart
///   final s = ref.watch(stringsProvider); // from locale_provider.dart
///   Text(s.send)
///   ```
class S {
  final Locale locale;
  const S(this.locale);

  /// Returns the translation for the current locale, falling back to English.
  String _t(
    String en, {
    String? ru,
    String? de,
    String? da,
    String? et,
    String? pt,
    String? uk,
  }) {
    switch (locale.languageCode) {
      case 'ru':
        return ru ?? en;
      case 'de':
        return de ?? en;
      case 'da':
        return da ?? en;
      case 'et':
        return et ?? en;
      case 'pt':
        return pt ?? en;
      case 'uk':
        return uk ?? en;
      default:
        return en;
    }
  }

  // ── App bar / navigation ────────────────────────────────────────────────
  String get appTitle => _t('Wallet Vaval',
      ru: 'Валет Vaval',
      de: 'Wallet Vaval',
      da: 'Wallet Vaval',
      et: 'Wallet Vaval',
      pt: 'Wallet Vaval',
      uk: 'Wallet Vaval');
  String get settings => _t('Settings',
      ru: 'Настройки',
      de: 'Einstellungen',
      da: 'Indstillinger',
      et: 'Seaded',
      pt: 'Configurações',
      uk: 'Налаштування');
  String get lockWallet => _t('Lock wallet',
      ru: 'Заблокировать',
      de: 'Wallet sperren',
      da: 'Lås pung',
      et: 'Lukusta rahakott',
      pt: 'Bloquear carteira',
      uk: 'Заблокувати гаманець');

  // ── Dashboard ───────────────────────────────────────────────────────────
  String get totalPortfolio => _t('Total Portfolio',
      ru: 'Мой портфель',
      de: 'Gesamtportfolio',
      da: 'Samlet portefølje',
      et: 'Kogu portfell',
      pt: 'Portfólio total',
      uk: 'Мій портфель');
  String get usdValue => _t('USD Value',
      ru: 'Стоимость в USD',
      de: 'USD-Wert',
      da: 'USD-værdi',
      et: 'USD väärtus',
      pt: 'Valor em USD',
      uk: 'Вартість у USD');
  String get balancesUnavailable => _t('Some balances unavailable',
      ru: 'Некоторые балансы недоступны',
      de: 'Einige Guthaben nicht verfügbar',
      da: 'Nogle saldi utilgængelige',
      et: 'Mõned saldod pole saadaval',
      pt: 'Alguns saldos indisponíveis',
      uk: 'Деякі баланси недоступні');

  // ── Asset actions ───────────────────────────────────────────────────────
  String get send => _t('Send',
      ru: 'Отправить',
      de: 'Senden',
      da: 'Send',
      et: 'Saada',
      pt: 'Enviar',
      uk: 'Надіслати');
  String get receive => _t('Receive',
      ru: 'Получить',
      de: 'Empfangen',
      da: 'Modtag',
      et: 'Võta vastu',
      pt: 'Receber',
      uk: 'Отримати');
  String get swap => _t('Swap',
      ru: 'Обмен',
      de: 'Tauschen',
      da: 'Byt',
      et: 'Vaheta',
      pt: 'Trocar',
      uk: 'Обмін');

  // ── Price ───────────────────────────────────────────────────────────────
  String get priceLoading => _t('Loading prices…',
      ru: 'Загрузка цен…',
      de: 'Preise werden geladen…',
      da: 'Indlæser priser…',
      et: 'Laen hindu…',
      pt: 'A carregar preços…',
      uk: 'Завантаження цін…');
  String get priceUnavailable => _t('Price unavailable',
      ru: 'Цена недоступна',
      de: 'Preis nicht verfügbar',
      da: 'Pris utilgængelig',
      et: 'Hind pole saadaval',
      pt: 'Preço indisponível',
      uk: 'Ціна недоступна');

  // ── Settings ────────────────────────────────────────────────────────────
  String get language => _t('Language',
      ru: 'Язык',
      de: 'Sprache',
      da: 'Sprog',
      et: 'Keel',
      pt: 'Idioma',
      uk: 'Мова');
  String get langEnglish => 'English';
  String get langRussian => 'Русский';
  String get langGerman => 'Deutsch';
  String get langDanish => 'Dansk';
  String get langEstonian => 'Eesti';
  String get langPortuguese => 'Português';
  String get langUkrainian => 'Українська';

  // ── Security settings ────────────────────────────────────────────────────
  String get security => _t('Security',
      ru: 'Безопасность',
      de: 'Sicherheit',
      da: 'Sikkerhed',
      et: 'Turvalisus',
      pt: 'Segurança',
      uk: 'Безпека');
  String get changePin => _t('Change PIN',
      ru: 'Изменить PIN',
      de: 'PIN ändern',
      da: 'Skift PIN',
      et: 'Muuda PIN',
      pt: 'Alterar PIN',
      uk: 'Змінити PIN');
  String get changePinDesc => _t('Update your 6-digit security PIN',
      ru: 'Обновите 6-значный PIN-код',
      de: '6-stellige Sicherheits-PIN aktualisieren',
      da: 'Opdater din 6-cifrede sikkerhedskode',
      et: 'Uuendage oma 6-kohaline PIN',
      pt: 'Atualize o seu PIN de segurança de 6 dígitos',
      uk: 'Оновіть 6-значний PIN-код безпеки');

  String get panicPin => _t('Panic PIN',
      ru: 'Паник PIN',
      de: 'Panik-PIN',
      da: 'Panik-PIN',
      et: 'Paanika PIN',
      pt: 'PIN de pânico',
      uk: 'Панічний PIN');
  String get panicPinDesc => _t(
      'If forced to unlock, use this PIN for a hidden, limited wallet',
      ru: 'При принуждении используйте этот PIN — откроется ограниченный кошелёк',
      de: 'Bei Zwang: dieser PIN zeigt eine eingeschränkte Wallet',
      da: 'Ved tvang: denne PIN viser en begrænset tegnebog',
      et: 'Sunni korral avab see PIN piiratud rahakoti',
      pt: 'Se forçado a desbloquear, use este PIN para carteira limitada',
      uk: 'Якщо змушують розблокувати — цей PIN покаже обмежений гаманець');
  String get panicPinRemove => _t('Remove panic PIN',
      ru: 'Удалить паник PIN',
      de: 'Panik-PIN entfernen',
      da: 'Fjern panik-PIN',
      et: 'Eemalda paanika PIN',
      pt: 'Remover PIN de pânico',
      uk: 'Видалити панічний PIN');
  String get panicPinRemoveConfirm => _t(
      'Remove your panic PIN? You can set it again later in Security.',
      ru: 'Удалить паник PIN? Позже можно настроить снова в разделе «Безопасность».',
      de: 'Panik-PIN entfernen? Sie können sie später unter Sicherheit neu anlegen.',
      da: 'Fjern panik-PIN? Du kan tilføje den igen under Sikkerhed.',
      et: 'Eemaldada paanika PIN? Saate hiljem uuesti seadistada.',
      pt: 'Remover o PIN de pânico? Pode configurá-lo de novo em Segurança.',
      uk: 'Видалити панічний PIN? Пізніше можна знову налаштувати в «Безпека».');
  String get duressModeBanner => _t(
      'Panic mode — portfolio hidden; send, receive, and swap are disabled.',
      ru: 'Режим паники — портфель скрыт; отправка, приём и обмен отключены.',
      de: 'Panikmodus — Portfolio verborgen; Senden, Empfangen und Swap aus.',
      da: 'Paniktilstand — portefølje skjult; send, modtag og swap er slået fra.',
      et: 'Paanikarežiim — portfell peidetud; saatmine, vastuvõtt ja vahetus keelatud.',
      pt: 'Modo pânico — carteira oculta; enviar, receber e swap desativados.',
      uk: 'Панічний режим — портфель приховано; надсилання, прийом і обмін вимкнено.');
  String get duressActionBlocked => _t(
      'Unavailable in panic mode. Lock the wallet and sign in with your main PIN.',
      ru: 'Недоступно в режиме паники. Заблокируйте кошелёк и войдите основным PIN.',
      de: 'Im Panikmodus nicht verfügbar. Sperren und mit Haupt-PIN anmelden.',
      da: 'Ikke tilgængelig i paniktilstand. Lås og log ind med hoved-PIN.',
      et: 'Paanikarežiimis pole saadaval. Lukusta ja logi sisse põhi-PIN-iga.',
      pt: 'Indisponível em modo pânico. Bloqueie e entre com o PIN principal.',
      uk: 'Недоступно в панічному режимі. Заблокуйте та увійдіть основним PIN.');
  String get duressSettingsBlocked => _t(
      'Quit panic mode: lock the wallet, then unlock with your main PIN.',
      ru: 'Выйти из режима паники: заблокируйте кошелёк и войдите основным PIN.',
      de: 'Panikmodus beenden: Wallet sperren, dann mit Haupt-PIN entsperren.',
      da: 'Afslut paniktilstand: lås tegnebogen og lås op med hoved-PIN.',
      et: 'Paanikarežiimist väljumine: lukusta rahakott ja ava põhi-PIN-iga.',
      pt: 'Sair do modo pânico: bloqueie e desbloqueie com o PIN principal.',
      uk: 'Вийти з панічного режиму: заблокуйте гаманець і розблокуйте основним PIN.');

  String get biometrics => _t('Biometric unlock',
      ru: 'Биометрический вход',
      de: 'Biometrische Entsperrung',
      da: 'Biometrisk oplåsning',
      et: 'Biomeetriline avamine',
      pt: 'Desbloqueio biométrico',
      uk: 'Біометричне розблокування');
  String get biometricsDesc => _t('Use fingerprint or face to unlock',
      ru: 'Вход по отпечатку пальца или лицу',
      de: 'Fingerabdruck oder Gesicht verwenden',
      da: 'Brug fingeraftryk eller ansigt til oplåsning',
      et: 'Kasutage avamiseks sõrmejälge või nägu',
      pt: 'Usar impressão digital ou rosto para desbloquear',
      uk: 'Використовувати відбиток пальця або обличчя');

  // ── Notifications ────────────────────────────────────────────────────────
  String get notifications => _t('Notifications',
      ru: 'Уведомления',
      de: 'Benachrichtigungen',
      da: 'Notifikationer',
      et: 'Teavitused',
      pt: 'Notificações',
      uk: 'Сповіщення');
  String get notifyTransactions => _t('Transaction alerts',
      ru: 'Уведомления о транзакциях',
      de: 'Transaktionsbenachrichtigungen',
      da: 'Transaktionsadvarsler',
      et: 'Tehinguteatised',
      pt: 'Alertas de transação',
      uk: 'Сповіщення про транзакції');
  String get notifyTransactionsDesc =>
      _t('Get notified when a transaction completes',
          ru: 'Получайте уведомления о завершённых транзакциях',
          de: 'Benachrichtigung bei abgeschlossener Transaktion',
          da: 'Få besked, når en transaktion er gennemført',
          et: 'Saage teada, kui tehing on lõpule viidud',
          pt: 'Receba uma notificação quando uma transação for concluída',
          uk: 'Отримуйте сповіщення про завершені транзакції');
  String get notifyPriceAlerts => _t('Price alerts',
      ru: 'Уведомления о ценах',
      de: 'Preisalarme',
      da: 'Prisadvarsler',
      et: 'Hinnateatised',
      pt: 'Alertas de preço',
      uk: 'Цінові сповіщення');
  String get notifyPriceAlertsDesc => _t('Alert on significant price movements',
      ru: 'Уведомление о значительных изменениях цен',
      de: 'Bei deutlichen Kursänderungen benachrichtigen',
      da: 'Advar om betydelige prisbevægelser',
      et: 'Teavitage oluliste hinnamuutuste korral',
      pt: 'Alertar em movimentos de preço significativos',
      uk: 'Сповіщення про значні зміни ціни');

  // ── Transaction history ──────────────────────────────────────────────────
  String get history => _t('Transaction History',
      ru: 'История транзакций',
      de: 'Transaktionsverlauf',
      da: 'Transaktionshistorik',
      et: 'Tehingute ajalugu',
      pt: 'Histórico de transações',
      uk: 'Історія транзакцій');
  String get historyEmpty => _t('No transactions yet',
      ru: 'Транзакций пока нет',
      de: 'Noch keine Transaktionen',
      da: 'Ingen transaktioner endnu',
      et: 'Tehinguid pole veel',
      pt: 'Ainda sem transações',
      uk: 'Поки немає транзакцій');
  String get historyViewAll => _t('View all transactions',
      ru: 'Смотреть все транзакции',
      de: 'Alle Transaktionen anzeigen',
      da: 'Se alle transaktioner',
      et: 'Vaata kõiki tehinguid',
      pt: 'Ver todas as transações',
      uk: 'Переглянути всі транзакції');
  String get historyTabOnChain => _t('On-chain',
      ru: 'Ончейн',
      de: 'On-Chain',
      da: 'On-chain',
      et: 'Ahelas',
      pt: 'On-chain',
      uk: 'Ончейн');
  String get historyChipAll => _t('All',
      ru: 'Все',
      de: 'Alle',
      da: 'Alle',
      et: 'Kõik',
      pt: 'Tudo',
      uk: 'Усе');
  String get historyBadgeOnChain => _t('On-chain',
      ru: 'Ончейн',
      de: 'On-Chain',
      da: 'On-chain',
      et: 'Ahelas',
      pt: 'On-chain',
      uk: 'Ончейн');
  String get historyEmptyUnified => _t(
      'No outgoing transfers yet. When you send assets, they will appear here.',
      ru: 'Исходящих переводов пока нет. После отправки они появятся здесь.',
      de: 'Noch keine ausgehenden Überweisungen. Nach dem Senden erscheinen sie hier.',
      da: 'Ingen udgående overførsler endnu. Når du sender, vises de her.',
      et: 'Väljuvaid ülekandeid pole veel. Pärast saatmist kuvatakse need siin.',
      pt: 'Ainda sem transferências enviadas. Após enviar, aparecem aqui.',
      uk: 'Вихідних переказів поки немає. Після відправлення вони з’являться тут.');
  String get historyEmptyFilter => _t('Nothing in this category yet.',
      ru: 'В этой категории пока ничего нет.',
      de: 'In dieser Kategorie ist noch nichts vorhanden.',
      da: 'Intet i denne kategori endnu.',
      et: 'Selles kategoorias pole veel midagi.',
      pt: 'Nada nesta categoria ainda.',
      uk: 'У цій категорії поки нічого немає.');
  String get historyClearAllTitle => _t('Clear all activity?',
      ru: 'Очистить всю активность?',
      de: 'Alle Aktivität löschen?',
      da: 'Ryd al aktivitet?',
      et: 'Kustutada kogu tegevus?',
      pt: 'Limpar toda a atividade?',
      uk: 'Очистити всю активність?');
  String get historyClearAllBody => _t(
      'This removes locally stored outgoing transfer history on this device.',
      ru: 'Это удалит локально сохранённую историю исходящих переводов на этом устройстве.',
      de: 'Dadurch wird der lokal gespeicherte Sendeverlauf auf diesem Gerät entfernt.',
      da: 'Dette fjerner lokalt gemt udgående overførselshistorik på denne enhed.',
      et: 'See eemaldab kohapeal salvestatud väljuva ülekannete ajaloo sellest seadmest.',
      pt: 'Isto remove o histórico local de transferências enviadas neste dispositivo.',
      uk: 'Це видалить локально збережену історію вихідних переказів на цьому пристрої.');
  String get historyMenuClearOnChain => _t('Clear on-chain history',
      ru: 'Очистить ончейн-историю',
      de: 'On-Chain-Verlauf löschen',
      da: 'Ryd on-chain historik',
      et: 'Tühjenda ahela ajalugu',
      pt: 'Limpar histórico on-chain',
      uk: 'Очистити ончейн-історію');
  String get historyMenuClearAll => _t('Clear everything',
      ru: 'Очистить всё',
      de: 'Alles löschen',
      da: 'Ryd alt',
      et: 'Tühjenda kõik',
      pt: 'Limpar tudo',
      uk: 'Очистити все');
  // ── Legal (store placeholders) ───────────────────────────────────────────
  String get legalSection => _t('Legal',
      ru: 'Право',
      de: 'Rechtliches',
      da: 'Juridisk',
      et: 'Juriidiline',
      pt: 'Legal',
      uk: 'Юридичне');
  String get legalTermsTitle => _t('Terms of Service',
      ru: 'Условия использования',
      de: 'Nutzungsbedingungen',
      da: 'Servicevilkår',
      et: 'Kasutustingimused',
      pt: 'Termos de serviço',
      uk: 'Умови використання');
  String get legalTermsDesc => _t('Rules for using Wallet Vaval',
      ru: 'Правила использования Валет Vaval',
      de: 'Regeln für die Nutzung von Wallet Vaval',
      da: 'Regler for brug af Wallet Vaval',
      et: 'Wallet Vaval kasutamise reeglid',
      pt: 'Regras de utilização do Wallet Vaval',
      uk: 'Правила використання Wallet Vaval');
  String get legalPrivacyTitle => _t('Privacy Policy',
      ru: 'Политика конфиденциальности',
      de: 'Datenschutzerklärung',
      da: 'Privatlivspolitik',
      et: 'Privaatsuspoliitika',
      pt: 'Política de privacidade',
      uk: 'Політика конфіденційності');
  String get legalPrivacyDesc => _t('How we handle your data',
      ru: 'Как мы обрабатываем ваши данные',
      de: 'Wie wir mit Ihren Daten umgehen',
      da: 'Sådan håndterer vi dine data',
      et: 'Kuidas me teie andmeid käsitleme',
      pt: 'Como tratamos os seus dados',
      uk: 'Як ми обробляємо ваші дані');

  /// Send screen: standard network fees only.
  String get sendFeeDisclosure => _t(
      'Ethereum (ETH and VAVAL), Solana, and TON charge standard network fees to miners or validators when you send. '
      'Those fees are not paid to the app publisher. Review the estimate for your chain before you confirm.',
      ru: 'Сети Ethereum (ETH и VAVAL), Solana и TON взимают обычные сетевые комиссии при отправке (операторам сети / валидаторам). '
          'Эти средства не идут издателю приложения. Проверьте оценку перед подтверждением.');

  String get sendFeeLineNetwork => _t(
      'Network fee: set by the destination blockchain and paid to validators or miners.',
      ru: 'Сетевая комиссия: определяется сетью назначения и выплачивается валидаторам/операторам сети.');
  String get sendFeeSmallTransferNote => _t(
      'Network fees can be high when chains are busy or when you send very small amounts. Please review before you confirm.',
      ru: 'Сетевые комиссии могут быть высокими при загруженности сети или при очень малых суммах. Проверьте перед подтверждением.');

  String get legalFeesHubTitle => _t('Legal',
      ru: 'Право',
      de: 'Rechtliches',
      da: 'Juridisk',
      et: 'Juriidiline',
      pt: 'Legal',
      uk: 'Юридичне');
  String get legalFeesHubDesc => _t(
      'Terms and Privacy Policy',
      ru: 'Условия и политика конфиденциальности',
      de: 'AGB und Datenschutz',
      da: 'Vilkår og privatlivspolitik',
      et: 'Tingimused ja privaatsuspoliitika',
      pt: 'Termos e política de privacidade',
      uk: 'Умови та політика конфіденційності');
  String get legalFeesMenuOpenTerms => _t('Open Terms of Service', ru: 'Открыть Условия использования');
  String get legalFeesMenuOpenPrivacy => _t('Open Privacy Policy', ru: 'Открыть Политику конфиденциальности');

  String get stripePaywallTitle => _t('Unlock Wallet Vaval',
      ru: 'Разблокировка Валет Vaval');
  String get stripePaywallBody => _t(
      'Use the button below to open Stripe’s secure Checkout page. After payment your browser opens our /success page, then you can return to Wallet Vaval; '
      'on-chain sends only incur normal network fees (e.g. Ethereum gas, Solana, TON).',
      ru: 'Нажмите кнопку ниже — откроется защищённая страница оплаты Stripe. После оплаты браузер откроет страницу /success, затем вы сможете вернуться в «Валет Vaval»; '
          'за переводы в блокчейне платите только обычные сетевые комиссии.',
      de: 'Öffnen Sie die sichere Stripe-Checkout-Seite. Danach nutzen Sie Wallet Vaval; On-Chain nur normale Netzwerkgebühren.',
      da: 'Åbn Stripes sikre betalingsside. Derefter Wallet Vaval; on-chain kun normale gebyrer.',
      et: 'Avage Stripe turvaline makseleht. Seejärel Wallet Vaval; plokiahelas tavatasud.',
      pt: 'Abra o Checkout seguro da Stripe. Depois use o Wallet Vaval; on-chain apenas taxas normais.',
      uk: 'Відкрийте безпечну сторінку Stripe Checkout. Потім користуйтесь Wallet Vaval; у мережі лише стандартні збори.');
  String get stripePriceLineTemplate => _t(
      'Access total (charged at Checkout): {amount}',
      ru: 'Сумма доступа (в Checkout): {amount}',
      de: 'Zugang gesamt (Checkout): {amount}',
      da: 'Adgang i alt (Checkout): {amount}',
      et: 'Juurdepääs kokku (Checkout): {amount}',
      pt: 'Total de acesso (Checkout): {amount}',
      uk: 'Сума доступу (Checkout): {amount}');
  String get stripePayButton => _t('Pay on Stripe’s website', ru: 'Оплатить на сайте Stripe');
  String get stripeBackendLabel => _t('Payment backend base URL (configure for your build):',
      ru: 'Базовый URL сервера оплаты (настройте для вашей сборки):');
  String get stripeMissingBackendUrl => _t(
      'Set --dart-define=STRIPE_BACKEND_URL=https://your-server.example (no trailing slash)',
      ru: 'Укажите --dart-define=STRIPE_BACKEND_URL=https://ваш-сервер.example (без слэша в конце)');
  String get stripeOpeningBrowser => _t('Opening Stripe…', ru: 'Открываем Stripe…');
  String get stripeThankYouTitle => _t('Thank you!', ru: 'Спасибо!');
  String get stripeThankYouBody => _t(
      'Your payment was successful. Wallet Vaval is unlocked — you can continue to the wallet.',
      ru: 'Оплата прошла успешно. «Валет Vaval» разблокирован — можно переходить к кошельку.',
      de: 'Zahlung erfolgreich. Wallet Vaval ist freigeschaltet.',
      da: 'Betaling gennemført. Wallet Vaval er låst op.',
      et: 'Makse õnnestus. Wallet Vaval on avatud.',
      pt: 'Pagamento concluído. Wallet Vaval desbloqueado.',
      uk: 'Оплата успішна. Wallet Vaval розблоковано.');
  String get stripeThankYouContinue => _t('Continue to wallet', ru: 'Перейти к кошельку');
  String get stripeCheckoutCanceled => _t(
      'Checkout was canceled. You can try again whenever you’re ready.',
      ru: 'Оплата отменена. Вы можете попробовать снова, когда будете готовы.',
      de: 'Checkout wurde abgebrochen. Sie können es später erneut versuchen.',
      da: 'Betalingen blev annulleret. Prøv igen, når du er klar.',
      et: 'Makse katkestati. Proovige uuesti, kui soovite.',
      pt: 'O checkout foi cancelado. Pode tentar novamente quando quiser.',
      uk: 'Оплату скасовано. Можна спробувати знову, коли будете готові.');
  String get stripePaymentNotCompleted => _t(
      'Payment was not completed. If your card was declined, try another card or contact your bank.',
      ru: 'Оплата не завершена. Если карта отклонена, попробуйте другую карту или обратитесь в банк.',
      de: 'Zahlung nicht abgeschlossen. Bei Kartenproblemen andere Karte nutzen oder Bank kontaktieren.',
      da: 'Betalingen blev ikke gennemført. Prøv et andet kort eller kontakt banken.',
      et: 'Makse ei lõppenud. Proovige teist kaarti või võtke ühendust pangaga.',
      pt: 'Pagamento não concluído. Experimente outro cartão ou contacte o banco.',
      uk: 'Оплату не завершено. Спробуйте іншу картку або зверніться до банку.');
  String get stripeNetworkError => _t(
      'Could not reach the payment server. Check your connection and backend URL.',
      ru: 'Не удалось связаться с сервером оплаты. Проверьте интернет и URL сервера.',
      de: 'Zahlungsserver nicht erreichbar. Verbindung und URL prüfen.',
      da: 'Kunne ikke nå betalingsserveren. Tjek forbindelse og URL.',
      et: 'Makseserveriga ei saanud ühendust. Kontrollige võrku ja URL-i.',
      pt: 'Não foi possível contactar o servidor de pagamentos. Verifique a ligação e o URL.',
      uk: 'Не вдалося зв’язатися з сервером оплати. Перевірте мережу та URL.');
  String get stripeBrowserOpenFailed => _t(
      'Could not open the browser for Stripe Checkout.',
      ru: 'Не удалось открыть браузер для оплаты Stripe.',
      de: 'Browser für Stripe Checkout konnte nicht geöffnet werden.',
      da: 'Kunne ikke åbne browseren til Stripe Checkout.',
      et: 'Stripe Checkouti brauserit ei saanud avada.',
      pt: 'Não foi possível abrir o browser para o Stripe Checkout.',
      uk: 'Не вдалося відкрити браузер для Stripe Checkout.');
  String get stripePublishableKeyMissingHint => _t(
      'Tip: set STRIPE_PUBLISHABLE_KEY via --dart-define (pk_… only; never sk_…).',
      ru: 'Подсказка: укажите STRIPE_PUBLISHABLE_KEY через --dart-define (только pk_…, не sk_…).',
      de: 'Tipp: STRIPE_PUBLISHABLE_KEY per --dart-define setzen (nur pk_…).',
      da: 'Tip: angiv STRIPE_PUBLISHABLE_KEY med --dart-define (kun pk_…).',
      et: 'Vihje: määrake STRIPE_PUBLISHABLE_KEY --dart-define abil (ainult pk_…).',
      pt: 'Dica: defina STRIPE_PUBLISHABLE_KEY com --dart-define (apenas pk_…).',
      uk: 'Підказка: задайте STRIPE_PUBLISHABLE_KEY через --dart-define (лише pk_…).');
  String get paywallLock => _t('Lock wallet', ru: 'Заблокировать кошелёк');

  // ── Support ──────────────────────────────────────────────────────────────
  String get support => _t('Support',
      ru: 'Поддержка',
      de: 'Support',
      da: 'Support',
      et: 'Tugi',
      pt: 'Suporte',
      uk: 'Підтримка');
  String get supportTitle => _t('Contact Support',
      ru: 'Связаться с поддержкой',
      de: 'Support kontaktieren',
      da: 'Kontakt support',
      et: 'Võtke ühendust toega',
      pt: 'Contactar suporte',
      uk: 'Зв\'язатися з підтримкою');
  String get supportDesc => _t(
      'Write to us directly and we\'ll help you as soon as possible.',
      ru: 'Напишите нам напрямую, и мы поможем вам как можно скорее.',
      de: 'Schreiben Sie uns direkt und wir helfen Ihnen so schnell wie möglich.',
      da: 'Skriv til os direkte, så hjælper vi dig hurtigst muligt.',
      et: 'Kirjutage meile otse ja me aitame teid niipea kui võimalik.',
      pt: 'Escreva-nos diretamente e ajudaremos o mais rapidamente possível.',
      uk: 'Напишіть нам безпосередньо, і ми допоможемо якнайшвидше.');
  String get supportNameLabel => _t('Your name',
      ru: 'Ваше имя',
      de: 'Ihr Name',
      da: 'Dit navn',
      et: 'Teie nimi',
      pt: 'O seu nome',
      uk: 'Ваше ім\'я');
  String get supportSubjectLabel => _t('Subject',
      ru: 'Тема',
      de: 'Betreff',
      da: 'Emne',
      et: 'Teema',
      pt: 'Assunto',
      uk: 'Тема');
  String get supportMessageLabel => _t('Message',
      ru: 'Сообщение',
      de: 'Nachricht',
      da: 'Besked',
      et: 'Sõnum',
      pt: 'Mensagem',
      uk: 'Повідомлення');
  String get supportSendButton => _t('Send message',
      ru: 'Отправить сообщение',
      de: 'Nachricht senden',
      da: 'Send besked',
      et: 'Saada sõnum',
      pt: 'Enviar mensagem',
      uk: 'Надіслати повідомлення');
  String get supportSentConfirm => _t('Message saved! We\'ll be in touch.',
      ru: 'Сообщение сохранено! Мы свяжемся с вами.',
      de: 'Nachricht gespeichert! Wir melden uns.',
      da: 'Besked gemt! Vi kontakter dig.',
      et: 'Sõnum salvestatud! Võtame teiega ühendust.',
      pt: 'Mensagem guardada! Entraremos em contacto.',
      uk: 'Повідомлення збережено! Ми зв\'яжемося з вами.');
  String get supportPreviousMessages => _t('Previous messages',
      ru: 'Предыдущие сообщения',
      de: 'Frühere Nachrichten',
      da: 'Tidligere beskeder',
      et: 'Varasemad sõnumid',
      pt: 'Mensagens anteriores',
      uk: 'Попередні повідомлення');
  String get supportNoMessages => _t('No messages yet',
      ru: 'Сообщений пока нет',
      de: 'Noch keine Nachrichten',
      da: 'Ingen beskeder endnu',
      et: 'Sõnumeid pole veel',
      pt: 'Ainda sem mensagens',
      uk: 'Повідомлень поки немає');

  // ── Network ─────────────────────────────────────────────────────────────
  String get network => _t('Network',
      ru: 'Сеть',
      de: 'Netzwerk',
      da: 'Netværk',
      et: 'Võrk',
      pt: 'Rede',
      uk: 'Мережа');
  String get networkMainnet => _t('Mainnet (Live)',
      ru: 'Mainnet (основная сеть)',
      de: 'Mainnet (Live)',
      da: 'Mainnet (Live)',
      et: 'Mainnet (Live)',
      pt: 'Mainnet (Produção)',
      uk: 'Mainnet (основна мережа)');
  String get networkTestnet => _t('Testnet (Test only)',
      ru: 'Testnet (тестовая сеть)',
      de: 'Testnet (nur Test)',
      da: 'Testnet (kun test)',
      et: 'Testnet (ainult test)',
      pt: 'Testnet (apenas teste)',
      uk: 'Testnet (тільки тест)');
  String get networkMainnetDesc => _t('Real transactions & balances',
      ru: 'Реальные транзакции и балансы',
      de: 'Echte Transaktionen & Guthaben',
      da: 'Rigtige transaktioner & saldi',
      et: 'Päris tehingud ja saldod',
      pt: 'Transações e saldos reais',
      uk: 'Реальні транзакції та баланси');
  String get networkTestnetDesc =>
      _t('Solana Devnet, Ethereum Sepolia, and TON testnet — no real funds',
          ru: 'Solana Devnet, Sepolia (Ethereum) и тестовая сеть TON — без реальных средств',
          de: 'Solana Devnet, Ethereum Sepolia und TON-Testnet — keine echten Mittel',
          da: 'Solana Devnet, Ethereum Sepolia og TON-testnet — ingen rigtige midler',
          et: 'Solana Devnet, Ethereum Sepolia ja TON testnet — pole päris vahendeid',
          pt: 'Solana Devnet, Ethereum Sepolia e testnet TON — sem fundos reais',
          uk: 'Solana Devnet, Ethereum Sepolia і тестова мережа TON — без реальних коштів');
  String get networkTestnetWarning =>
      _t('⚠ Testnet active — real funds are not accessible',
          ru: '⚠ Тестовая сеть активна — реальные средства недоступны',
          de: '⚠ Testnet aktiv — echte Mittel nicht zugänglich',
          da: '⚠ Testnet aktiv — rigtige midler er ikke tilgængelige',
          et: '⚠ Testnet aktiivne — päris vahendid pole ligipääsetavad',
          pt: '⚠ Testnet ativo — fundos reais não acessíveis',
          uk: '⚠ Тестова мережа активна — реальні кошти недоступні');

  // ── RPC error hints ──────────────────────────────────────────────────────
  String get rpcKeyHintEth =>
      '--dart-define=ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY';
  String get rpcKeyHintSol =>
      '--dart-define=SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY';
  String get rpcKeyHintTon => '--dart-define=TONCENTER_API_KEY=YOUR_KEY';

  // ── Swap screen ─────────────────────────────────────────────────────────
  String get swapTitle => _t('Swap / Convert',
      ru: 'Конвертация',
      de: 'Tauschen / Konvertieren',
      da: 'Byt / Konverter',
      et: 'Vaheta / Teisenda',
      pt: 'Trocar / Converter',
      uk: 'Обмін / Конвертація');
  String get swapFrom => _t('From',
      ru: 'Из', de: 'Von', da: 'Fra', et: 'Alates', pt: 'De', uk: 'З');
  String get swapTo => _t('To',
      ru: 'В', de: 'Nach', da: 'Til', et: 'Kuni', pt: 'Para', uk: 'До');
  String get swapAmount => _t('Amount',
      ru: 'Сумма',
      de: 'Betrag',
      da: 'Beløb',
      et: 'Summa',
      pt: 'Quantia',
      uk: 'Сума');
  String get swapResult => _t('You receive',
      ru: 'Вы получите',
      de: 'Sie erhalten',
      da: 'Du modtager',
      et: 'Saate',
      pt: 'Você receberá',
      uk: 'Ви отримаєте');
  String get swapRate => _t('Rate',
      ru: 'Курс', de: 'Kurs', da: 'Kurs', et: 'Kurss', pt: 'Taxa', uk: 'Курс');
  String get swapNote => _t(
      'Estimate based on live market prices. Actual swap requires a DEX.',
      ru: 'Расчёт основан на текущих рыночных ценах. Реальный обмен происходит через DEX.',
      de: 'Schätzung basiert auf aktuellen Marktpreisen. Echter Tausch erfordert einen DEX.',
      da: 'Estimat baseret på aktuelle markedspriser. Faktisk bytte kræver en DEX.',
      et: 'Hinnang põhineb praegustel turuhindadel. Tegelik vahetus nõuab DEX-i.',
      pt: 'Estimativa baseada em preços de mercado atuais. A troca real requer uma DEX.',
      uk: 'Розрахунок базується на поточних ринкових цінах. Реальний обмін відбувається через DEX.');
  String get swapPricesMissing => _t('Prices not yet loaded.',
      ru: 'Цены ещё не загружены.',
      de: 'Preise noch nicht geladen.',
      da: 'Priser ikke indlæst endnu.',
      et: 'Hinnad pole veel laaditud.',
      pt: 'Preços ainda não carregados.',
      uk: 'Ціни ще не завантажені.');

  // ── Send screen ─────────────────────────────────────────────────────────
  String get sendTitle => _t('Send',
      ru: 'Отправить',
      de: 'Senden',
      da: 'Send',
      et: 'Saada',
      pt: 'Enviar',
      uk: 'Надіслати');
  String get recipientAddress => _t('Recipient address',
      ru: 'Адрес получателя',
      de: 'Empfängeradresse',
      da: 'Modtageradresse',
      et: 'Saaja aadress',
      pt: 'Endereço do destinatário',
      uk: 'Адреса отримувача');
  String get amountLabel => _t('Amount',
      ru: 'Количество',
      de: 'Betrag',
      da: 'Beløb',
      et: 'Summa',
      pt: 'Quantia',
      uk: 'Кількість');
  String get maxBalance => 'MAX';
  String get confirmSend => _t('Confirm send',
      ru: 'Подтвердить отправку',
      de: 'Senden bestätigen',
      da: 'Bekræft afsendelse',
      et: 'Kinnita saatmine',
      pt: 'Confirmar envio',
      uk: 'Підтвердити відправлення');

  // ── Receive screen ──────────────────────────────────────────────────────
  String get receiveTitle => _t('Receive',
      ru: 'Получить',
      de: 'Empfangen',
      da: 'Modtag',
      et: 'Võta vastu',
      pt: 'Receber',
      uk: 'Отримати');
  String get yourAddress => _t('Your address',
      ru: 'Ваш адрес',
      de: 'Ihre Adresse',
      da: 'Din adresse',
      et: 'Teie aadress',
      pt: 'O seu endereço',
      uk: 'Ваша адреса');
  String get copyAddress => _t('Copy address',
      ru: 'Скопировать',
      de: 'Adresse kopieren',
      da: 'Kopiér adresse',
      et: 'Kopeeri aadress',
      pt: 'Copiar endereço',
      uk: 'Скопіювати адресу');
  String get addressCopied => _t('Address copied',
      ru: 'Адрес скопирован',
      de: 'Adresse kopiert',
      da: 'Adresse kopieret',
      et: 'Aadress kopeeritud',
      pt: 'Endereço copiado',
      uk: 'Адресу скопійовано');

  // ── DApp Browser ─────────────────────────────────────────────────────────
  String get browserTitle => _t('DApp Browser',
      ru: 'Браузер DApp',
      de: 'DApp-Browser',
      da: 'DApp Browser',
      et: 'DApp brauser',
      pt: 'Browser DApp',
      uk: 'Браузер DApp');
  String get browserUrlHint => _t('Enter URL or search…',
      ru: 'Введите URL или поиск…',
      de: 'URL oder Suche eingeben…',
      da: 'Indtast URL eller søg…',
      et: 'Sisesta URL või otsi…',
      pt: 'Introduza URL ou pesquise…',
      uk: 'Введіть URL або пошук…');
  String get browserQuickAccess => _t('Quick access',
      ru: 'Быстрый доступ',
      de: 'Schnellzugriff',
      da: 'Hurtig adgang',
      et: 'Kiirjuurdepääs',
      pt: 'Acesso rápido',
      uk: 'Швидкий доступ');
  String get browserNotSupported =>
      _t('WebView is not supported on this platform.',
          ru: 'WebView не поддерживается на этой платформе.',
          de: 'WebView wird auf dieser Plattform nicht unterstützt.',
          da: 'WebView understøttes ikke på denne platform.',
          et: 'WebView ei ole sellel platvormil toetatud.',
          pt: 'WebView não é suportado nesta plataforma.',
          uk: 'WebView не підтримується на цій платформі.');
}
