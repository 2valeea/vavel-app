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
  String get appTitle => _t('VAVEL WALLET',
      ru: 'VAVEL КОШЕЛЁК',
      de: 'VAVEL WALLET',
      da: 'VAVEL PUNG',
      et: 'VAVEL RAHAKOTT',
      pt: 'VAVEL CARTEIRA',
      uk: 'VAVEL ГАМАНЕЦЬ');
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
  String get historyTabWalletConnect => _t('WalletConnect',
      ru: 'WalletConnect',
      de: 'WalletConnect',
      da: 'WalletConnect',
      et: 'WalletConnect',
      pt: 'WalletConnect',
      uk: 'WalletConnect');
  String get historyWcEmpty => _t(
      'No WalletConnect activity yet. Approvals, signatures, and transactions from dApp Connect will appear here.',
      ru: 'Пока нет активности WalletConnect. Подключения, подписи и транзакции из раздела dApp Connect появятся здесь.',
      de: 'Noch keine WalletConnect-Aktivität. Genehmigungen, Signaturen und Transaktionen aus dApp Connect erscheinen hier.',
      da: 'Ingen WalletConnect-aktivitet endnu. Godkendelser, signaturer og transaktioner fra dApp Connect vises her.',
      et: 'WalletConnecti tegevust pole veel. dApp Connect heakskiidud, allkirjad ja tehingud kuvatakse siin.',
      pt: 'Ainda sem atividade WalletConnect. Aprovações, assinaturas e transações do dApp Connect aparecem aqui.',
      uk: 'Поки немає активності WalletConnect. Підтвердження, підписи та транзакції з dApp Connect з’являться тут.');
  String get historyClearWcTitle => _t('Clear WalletConnect log?',
      ru: 'Очистить журнал WalletConnect?',
      de: 'WalletConnect-Protokoll löschen?',
      da: 'Ryd WalletConnect-log?',
      et: 'Kustutada WalletConnecti logi?',
      pt: 'Limpar registo WalletConnect?',
      uk: 'Очистити журнал WalletConnect?');
  String get historyClearWcBody => _t(
      'This removes locally stored WalletConnect session and signing history from this device.',
      ru: 'Это удалит локально сохранённую историю сессий и подписей WalletConnect на этом устройстве.',
      de: 'Dadurch wird die lokal gespeicherte WalletConnect-Sitzungs- und Signaturhistorie auf diesem Gerät entfernt.',
      da: 'Dette fjerner lokalt gemt WalletConnect-session og signeringshistorik på denne enhed.',
      et: 'See eemaldab selles seadmes kohapeal salvestatud WalletConnecti seansi- ja allkirjade ajaloo.',
      pt: 'Isto remove o histórico local de sessões e assinaturas WalletConnect neste dispositivo.',
      uk: 'Це видалить локально збережену історію сесій і підписів WalletConnect на цьому пристрої.');
  String get historyClearWcAction => _t('Clear log',
      ru: 'Очистить',
      de: 'Protokoll löschen',
      da: 'Ryd log',
      et: 'Tühjenda logi',
      pt: 'Limpar registo',
      uk: 'Очистити');

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
  String get historyBadgeDapp => _t('dApp',
      ru: 'dApp',
      de: 'dApp',
      da: 'dApp',
      et: 'dApp',
      pt: 'dApp',
      uk: 'dApp');
  String get historyEmptyUnified => _t(
      'No activity yet. Outgoing transfers and WalletConnect events will appear here in one timeline.',
      ru:
          'Пока нет активности. Исходящие переводы и события WalletConnect появятся здесь в одной ленте.',
      de:
          'Noch keine Aktivität. Ausgehende Überweisungen und WalletConnect-Ereignisse erscheinen hier in einer Zeitleiste.',
      da:
          'Ingen aktivitet endnu. Udgående overførsler og WalletConnect-begivenheder vises her i én tidslinje.',
      et:
          'Tegevust pole veel. Väljuvad ülekanded ja WalletConnecti sündmused kuvatakse siin ühel ajajoonel.',
      pt:
          'Ainda sem atividade. Transferências enviadas e eventos WalletConnect aparecem aqui numa única linha do tempo.',
      uk:
          'Поки немає активності. Вихідні перекази та події WalletConnect з’являться тут в одній стрічці.');
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
      'This removes on-chain send history and the WalletConnect activity log stored on this device.',
      ru:
          'Это удалит историю исходящих переводов и журнал WalletConnect, сохранённые на этом устройстве.',
      de:
          'Dadurch werden der On-Chain-Sendeverlauf und das WalletConnect-Aktivitätsprotokoll auf diesem Gerät entfernt.',
      da:
          'Dette fjerner on-chain sendehistorik og WalletConnect-aktivitetslog på denne enhed.',
      et:
          'See eemaldab ahelas väljasaatmiste ajaloo ja WalletConnecti tegevuse logi sellest seadmest.',
      pt:
          'Isto remove o histórico de envios on-chain e o registo de atividade WalletConnect neste dispositivo.',
      uk:
          'Це видалить історію відправлень ончейн і журнал активності WalletConnect на цьому пристрої.');
  String get historyMenuClearOnChain => _t('Clear on-chain history',
      ru: 'Очистить ончейн-историю',
      de: 'On-Chain-Verlauf löschen',
      da: 'Ryd on-chain historik',
      et: 'Tühjenda ahela ajalugu',
      pt: 'Limpar histórico on-chain',
      uk: 'Очистити ончейн-історію');
  String get historyMenuClearWc => _t('Clear dApp activity log',
      ru: 'Очистить журнал dApp',
      de: 'dApp-Aktivitätsprotokoll löschen',
      da: 'Ryd dApp-aktivitetslog',
      et: 'Tühjenda dAppi tegevuse logi',
      pt: 'Limpar registo de atividade dApp',
      uk: 'Очистити журнал активності dApp');
  String get historyMenuClearAll => _t('Clear everything',
      ru: 'Очистить всё',
      de: 'Alles löschen',
      da: 'Ryd alt',
      et: 'Tühjenda kõik',
      pt: 'Limpar tudo',
      uk: 'Очистити все');
  String get historyLoadingWcLine => _t('Loading dApp activity…',
      ru: 'Загрузка активности dApp…',
      de: 'dApp-Aktivität wird geladen…',
      da: 'Indlæser dApp-aktivitet…',
      et: 'Laadin dAppi tegevust…',
      pt: 'A carregar atividade dApp…',
      uk: 'Завантаження активності dApp…');
  String get historyWcLoadErrorLead => _t(
      'Could not refresh dApp activity. On-chain items are still shown.',
      ru:
          'Не удалось обновить активность dApp. Ончейн-записи по-прежнему отображаются.',
      de:
          'dApp-Aktivität konnte nicht aktualisiert werden. On-Chain-Einträge werden weiterhin angezeigt.',
      da:
          'Kunne ikke opdatere dApp-aktivitet. On-chain-poster vises stadig.',
      et:
          'dAppi tegevust ei saanud värskendada. Ahela kanded on endiselt näha.',
      pt:
          'Não foi possível atualizar a atividade dApp. Itens on-chain continuam visíveis.',
      uk:
          'Не вдалося оновити активність dApp. Ончейн-записи все ще відображаються.');

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
  String get legalTermsDesc => _t('Rules for using Vavel Wallet',
      ru: 'Правила использования Vavel Wallet',
      de: 'Regeln für die Nutzung von Vavel Wallet',
      da: 'Regler for brug af Vavel Wallet',
      et: 'Vavel Walleti kasutamise reeglid',
      pt: 'Regras de utilização da Vavel Wallet',
      uk: 'Правила використання Vavel Wallet');
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
      ru: 'Mainnet (боевая сеть)',
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
      _t('Devnet / Sepolia / Testnet3 — no real funds',
          ru: 'Devnet/Sepolia/Testnet3 — без реальных средств',
          de: 'Devnet/Sepolia/Testnet3 — keine echten Mittel',
          da: 'Devnet/Sepolia/Testnet3 — ingen rigtige midler',
          et: 'Devnet/Sepolia/Testnet3 — pole päris vahendeid',
          pt: 'Devnet/Sepolia/Testnet3 — sem fundos reais',
          uk: 'Devnet/Sepolia/Testnet3 — без реальних коштів');
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
