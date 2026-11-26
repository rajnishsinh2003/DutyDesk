class HandoffContact {
  final String phone;
  final String whatsapp;
  final String email;

  const HandoffContact({
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
  });

  bool get hasAny =>
      phone.trim().isNotEmpty ||
      whatsapp.trim().isNotEmpty ||
      email.trim().isNotEmpty;

  factory HandoffContact.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HandoffContact();
    return HandoffContact(
      phone: map['phone'] as String? ?? '',
      whatsapp: map['whatsapp'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'phone': phone.trim(),
        'whatsapp': whatsapp.trim(),
        'email': email.trim(),
      };

  HandoffContact copyWith({String? phone, String? whatsapp, String? email}) =>
      HandoffContact(
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        email: email ?? this.email,
      );
}

class ChatbotSettings {
  final bool landingEnabled;
  final bool invigilatorEnabled;
  final String botName;
  final Map<String, String> welcomeMessage;
  final String pinnedAnnouncement;
  final Map<String, Map<String, List<String>>> suggestedQuestions;
  final Map<String, String> fallbackMessage;
  final String systemPromptAdditions;
  final bool answerOnlyFromDocuments;
  final double similarityThreshold;
  final double temperature;
  final int maxInputLength;
  final int perSessionMessageCap;
  final int dailyTokenBudget;
  final int retentionDays;
  final HandoffContact handoffContact;

  const ChatbotSettings({
    this.landingEnabled = true,
    this.invigilatorEnabled = true,
    this.botName = 'DutyDesk AI Assistant',
    this.welcomeMessage = const {
      'en':
          'Hello! I am DutyDesk AI Assistant. Ask me about exam duty guidelines, reporting times, or platform features.',
      'hi':
          'नमस्ते! मैं DutyDesk AI सहायक हूँ। परीक्षा ड्यूटी नियमों, रिपोर्टिंग समय या ऐप सुविधाओं के बारे में पूछें।',
      'gu':
          'નમસ્તે! હું DutyDesk AI સહાયક છું. પરીક્ષા ડ્યુટી નિયમો, રિપોર્ટિંગ સમય અથવા એપ્લિકેશન સુવિધાઓ વિશે પૂછો.',
    },
    this.pinnedAnnouncement = '',
    this.suggestedQuestions = const {
      'landing': {
        'en': [
          'What is DutyDesk?',
          'How does geofence attendance work?',
          'What roles does DutyDesk support?'
        ],
        'hi': [
          'DutyDesk क्या है?',
          'जियोफेंस उपस्थिति कैसे काम करती है?',
        ],
        'gu': [
          'DutyDesk શું છે?',
          'જિયોફેન્સ હાજરી કેવી રીતે કામ કરે છે?',
        ],
      },
      'invigilator': {
        'en': [
          'What is the reporting time?',
          'How is remuneration calculated?',
          'How do I report an exam incident?'
        ],
        'hi': [
          'रिपोर्टिंग समय क्या है?',
          'पारिश्रमिक की गणना कैसे होती है?',
        ],
        'gu': [
          'રિપોર્ટિંગ સમય શું છે?',
          'મહેનતાણું કેવી રીતે ગણાય છે?',
        ],
      },
    },
    this.fallbackMessage = const {
      'en':
          'I could not find an exact answer in our official documents. Please contact support below.',
      'hi':
          'मुझे हमारे आधिकारिक दस्तावेज़ों में इसका सटीक उत्तर नहीं मिला। कृपया नीचे दिए गए सहायता संपर्क का उपयोग करें।',
      'gu':
          'મને અમારા સત્તાવાર દસ્તાવેજોમાં આનો ચોક્કસ જવાબ મળ્યો નથી. કૃપા કરીને નીચેના સપોર્ટ સંપર્કનો ઉપયોગ કરો.',
    },
    this.systemPromptAdditions = '',
    this.answerOnlyFromDocuments = true,
    this.similarityThreshold = 0.55,
    this.temperature = 0.2,
    this.maxInputLength = 500,
    this.perSessionMessageCap = 50,
    this.dailyTokenBudget = 500000,
    this.retentionDays = 90,
    this.handoffContact = const HandoffContact(),
  });

  String welcomeForLocale(String locale) =>
      welcomeMessage[locale]?.isNotEmpty == true
          ? welcomeMessage[locale]!
          : (welcomeMessage['en'] ?? '');

  String fallbackForLocale(String locale) =>
      fallbackMessage[locale]?.isNotEmpty == true
          ? fallbackMessage[locale]!
          : (fallbackMessage['en'] ?? '');

  List<String> suggestionsFor(String surface, String locale) {
    final surfaceMap = suggestedQuestions[surface];
    if (surfaceMap == null) return [];
    final list = surfaceMap[locale];
    if (list != null && list.isNotEmpty) return list;
    return surfaceMap['en'] ?? [];
  }

  factory ChatbotSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ChatbotSettings();
    const defaults = ChatbotSettings();

    Map<String, String> parseStringMap(dynamic raw, Map<String, String> fallback) {
      if (raw is! Map) return fallback;
      final out = Map<String, String>.from(fallback);
      raw.forEach((k, v) {
        if (v is String) out[k.toString()] = v;
      });
      return out;
    }

    Map<String, Map<String, List<String>>> parseSuggestions(dynamic raw) {
      if (raw is! Map) return defaults.suggestedQuestions;
      final out = <String, Map<String, List<String>>>{};
      for (final surface in ['landing', 'invigilator']) {
        final sRaw = raw[surface];
        final langMap = <String, List<String>>{};
        if (sRaw is Map) {
          sRaw.forEach((lang, items) {
            if (items is List) {
              langMap[lang.toString()] =
                  items.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
            }
          });
        }
        out[surface] = langMap.isEmpty
            ? (defaults.suggestedQuestions[surface] ?? {})
            : langMap;
      }
      return out;
    }

    return ChatbotSettings(
      landingEnabled: map['landingEnabled'] as bool? ?? true,
      invigilatorEnabled: map['invigilatorEnabled'] as bool? ?? true,
      botName: (map['botName'] as String?)?.isNotEmpty == true
          ? map['botName'] as String
          : defaults.botName,
      welcomeMessage: parseStringMap(map['welcomeMessage'], defaults.welcomeMessage),
      pinnedAnnouncement: map['pinnedAnnouncement'] as String? ?? '',
      suggestedQuestions: parseSuggestions(map['suggestedQuestions']),
      fallbackMessage: parseStringMap(map['fallbackMessage'], defaults.fallbackMessage),
      systemPromptAdditions: map['systemPromptAdditions'] as String? ?? '',
      answerOnlyFromDocuments: map['answerOnlyFromDocuments'] as bool? ?? true,
      similarityThreshold: (map['similarityThreshold'] as num?)?.toDouble() ?? 0.55,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.2,
      maxInputLength: (map['maxInputLength'] as num?)?.toInt() ?? 500,
      perSessionMessageCap: (map['perSessionMessageCap'] as num?)?.toInt() ?? 50,
      dailyTokenBudget: (map['dailyTokenBudget'] as num?)?.toInt() ?? 500000,
      retentionDays: (map['retentionDays'] as num?)?.toInt() ?? 90,
      handoffContact: HandoffContact.fromMap(
        map['handoffContact'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'landingEnabled': landingEnabled,
        'invigilatorEnabled': invigilatorEnabled,
        'botName': botName,
        'welcomeMessage': welcomeMessage,
        'pinnedAnnouncement': pinnedAnnouncement,
        'suggestedQuestions': suggestedQuestions,
        'fallbackMessage': fallbackMessage,
        'systemPromptAdditions': systemPromptAdditions,
        'answerOnlyFromDocuments': answerOnlyFromDocuments,
        'similarityThreshold': similarityThreshold,
        'temperature': temperature,
        'maxInputLength': maxInputLength,
        'perSessionMessageCap': perSessionMessageCap,
        'dailyTokenBudget': dailyTokenBudget,
        'retentionDays': retentionDays,
        'handoffContact': handoffContact.toMap(),
      };

  ChatbotSettings copyWith({
    bool? landingEnabled,
    bool? invigilatorEnabled,
    String? botName,
    Map<String, String>? welcomeMessage,
    String? pinnedAnnouncement,
    Map<String, Map<String, List<String>>>? suggestedQuestions,
    Map<String, String>? fallbackMessage,
    String? systemPromptAdditions,
    bool? answerOnlyFromDocuments,
    double? similarityThreshold,
    double? temperature,
    int? maxInputLength,
    int? perSessionMessageCap,
    int? dailyTokenBudget,
    int? retentionDays,
    HandoffContact? handoffContact,
  }) {
    return ChatbotSettings(
      landingEnabled: landingEnabled ?? this.landingEnabled,
      invigilatorEnabled: invigilatorEnabled ?? this.invigilatorEnabled,
      botName: botName ?? this.botName,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      pinnedAnnouncement: pinnedAnnouncement ?? this.pinnedAnnouncement,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      fallbackMessage: fallbackMessage ?? this.fallbackMessage,
      systemPromptAdditions:
          systemPromptAdditions ?? this.systemPromptAdditions,
      answerOnlyFromDocuments:
          answerOnlyFromDocuments ?? this.answerOnlyFromDocuments,
      similarityThreshold: similarityThreshold ?? this.similarityThreshold,
      temperature: temperature ?? this.temperature,
      maxInputLength: maxInputLength ?? this.maxInputLength,
      perSessionMessageCap: perSessionMessageCap ?? this.perSessionMessageCap,
      dailyTokenBudget: dailyTokenBudget ?? this.dailyTokenBudget,
      retentionDays: retentionDays ?? this.retentionDays,
      handoffContact: handoffContact ?? this.handoffContact,
    );
  }
}
