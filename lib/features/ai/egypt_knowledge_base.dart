import '/core/utils/arabic_normalizer.dart';
import '/features/guide/egypt_guide_page.dart';
import 'voice_assistant_models.dart';

/// Offline-ready Egyptian accessibility rights, services, transit, and official
/// hotlines knowledge base powering the ONEWAY Voice Assistant.
class EgyptKnowledgeBase {
  EgyptKnowledgeBase._();

  static const String mossPortalUrl = 'https://rdis.moss.gov.eg/';

  /// Official Egyptian emergency and disability support hotlines.
  static const List<EgyptianHotline> hotlines = [
    EgyptianHotline(
      id: 'ambulance',
      number: '123',
      nameAr: 'الإسعاف المصري',
      nameEn: 'Egyptian Ambulance',
      descriptionAr: 'الطوارئ الطبية والإسعاف السريع على مدار 24 ساعة.',
      descriptionEn: '24/7 medical emergency & ambulance service.',
      keywords: ['اسعاف', 'الاسعاف', '123', 'ambulance', 'طوارئ طبيه'],
      isEmergency: true,
    ),
    EgyptianHotline(
      id: 'police',
      number: '122',
      nameAr: 'شرطة النجدة',
      nameEn: 'Emergency Police',
      descriptionAr: 'شرطة النجدة للطوارئ الأمنية في جميع المحافظات.',
      descriptionEn: 'National emergency police hotline across Egypt.',
      keywords: ['الشرطه', 'شرطه', 'النجده', '122', 'police', 'بوليس'],
      isEmergency: true,
    ),
    EgyptianHotline(
      id: 'fire',
      number: '180',
      nameAr: 'المطافئ والحماية المدنية',
      nameEn: 'Fire & Civil Protection',
      descriptionAr: 'طوارئ الحرائق والإنقاذ والحماية المدنية.',
      descriptionEn: 'Firefighting and civil rescue emergency hotline.',
      keywords: ['مطافئ', 'المطافي', 'حريق', 'حريقه', '180', 'fire'],
      isEmergency: true,
    ),
    EgyptianHotline(
      id: 'ncpd',
      number: '16736',
      nameAr: 'المجلس القومي للأشخاص ذوي الإعاقة',
      nameEn: 'National Council for Persons with Disabilities',
      descriptionAr:
          'الاستشارات القانونية، متابعة الحقوق، والإبلاغ عن مخالفات الإتاحة.',
      descriptionEn:
          'Disability rights support, legal advice, and reporting violations.',
      keywords: [
        'المجلس القومي',
        'مجلس الاعاقه',
        '16736',
        'national council',
        'مخالفه اتاحه',
      ],
    ),
    EgyptianHotline(
      id: 'moss',
      number: '16439',
      nameAr: 'وزارة التضامن الاجتماعي',
      nameEn: 'Ministry of Social Solidarity',
      descriptionAr:
          'الاستعلام عن بطاقة الخدمات المتكاملة، مكاتب التأهيل، ومعاش كرامة.',
      descriptionEn:
          'Integrated Services Card status, rehab offices, and Karama support.',
      keywords: [
        'التضامن',
        'وزاره التضامن',
        '16439',
        'solidarity',
        'مكتب التاهيل',
      ],
    ),
    EgyptianHotline(
      id: 'cabinet',
      number: '16528',
      nameAr: 'منظومة الشكاوى الحكومية (مجلس الوزراء)',
      nameEn: 'Cabinet Government Complaints Hotline',
      descriptionAr: 'تقديم الشكاوى الرسمية ضد أي جهة حكومية أو خدمة عامة.',
      descriptionEn: 'Official complaints against public facilities or services.',
      keywords: [
        'مجلس الوزراء',
        'شكاوي حكوميه',
        'الشكاوي الحكوميه',
        '16528',
        'cabinet',
      ],
    ),
  ];

  /// Attempts to match an explicit hotline request (either asking for the
  /// number or asking to call it).
  static AIResponse? matchHotlineQuery(
    String normalizedQuery, {
    required bool isEnglish,
  }) {
    final wantsCall = normalizedQuery.contains('اتصل') ||
        normalizedQuery.contains('كلم') ||
        normalizedQuery.contains('رن علي') ||
        normalizedQuery.contains('اطلب') ||
        normalizedQuery.contains('call ') ||
        normalizedQuery.contains('dial ');

    // Asking for all hotlines
    if (normalizedQuery.contains('ارقام الطوارئ') ||
        normalizedQuery.contains('الخطوط الساخنه') ||
        normalizedQuery.contains('ارقام رسميه') ||
        normalizedQuery.contains('ارقام مهمه') ||
        normalizedQuery.contains('hotlines') ||
        normalizedQuery.contains('emergency numbers')) {
      const replyAr = 'اتفضل أهم الأرقام الرسمية والخطوط الساخنة في مصر:\n'
          '• الإسعاف: 123\n'
          '• شرطة النجدة: 122\n'
          '• المطافئ: 180\n'
          '• المجلس القومي للأشخاص ذوي الإعاقة: 16736\n'
          '• وزارة التضامن الاجتماعي: 16439\n'
          '• شكاوى مجلس الوزراء: 16528\n'
          'دوس على أي زرار تحت عشان تتصل على طول.';
      const replyEn = 'Here are the official hotlines in Egypt:\n'
          '• Ambulance: 123\n'
          '• Police: 122\n'
          '• Fire & Rescue: 180\n'
          '• National Council for Disabilities: 16736\n'
          '• Ministry of Social Solidarity: 16439\n'
          '• Cabinet Complaints: 16528\n'
          'Tap any button below to dial directly.';
      return AIResponse(
        intent: AIIntentType.egyptGuide,
        replyText: isEnglish ? replyEn : replyAr,
        spokenText: isEnglish
            ? 'Official Egyptian hotlines: Ambulance 123, Police 122, Disability Council 16736, and Ministry of Social Solidarity 16439.'
            : 'أهم الأرقام الرسمية في مصر: الإسعاف 123، والنجدة 122، والمجلس القومي لذوي الإعاقة 16736، ووزارة التضامن 16439. تقدر تدوس على أي رقم وتتصل فوراً.',
        quickActions: hotlines
            .map(
              (h) => AssistantAction(
                type: AssistantActionType.callPhone,
                labelAr: 'اتصال: ${h.nameAr} (${h.number})',
                labelEn: 'Call ${h.nameEn} (${h.number})',
                phoneNumber: h.number,
                iconName: 'phone',
              ),
            )
            .toList(),
        followUpSuggestions: isEnglish
            ? const ['Open Egypt Guide', 'Trigger SOS to companion']
            : const ['افتح دليلك في مصر', 'اطلب استغاثة من مرافقي'],
        isEnglish: isEnglish,
      );
    }

    for (final hotline in hotlines) {
      final matched = hotline.keywords.any(
        (kw) => normalizedQuery.contains(ArabicNormalizer.normalize(kw)),
      );
      if (!matched) continue;

      // Avoid hijacking personal SOS ("نجدة" + "مرافق" / "موقعي")
      if (hotline.id == 'police' &&
          (normalizedQuery.contains('مرافق') ||
              normalizedQuery.contains('موقعي') ||
              normalizedQuery.contains('استغاثه'))) {
        continue;
      }

      final callAction = AssistantAction(
        type: AssistantActionType.callPhone,
        labelAr: 'اتصال بـ ${hotline.nameAr} (${hotline.number})',
        labelEn: 'Call ${hotline.nameEn} (${hotline.number})',
        phoneNumber: hotline.number,
        autoExecute: wantsCall,
        iconName: 'phone',
      );

      final replyAr = wantsCall
          ? 'حاضر، بفتحلك الاتصال بـ ${hotline.nameAr} على رقم ${hotline.number} دلوقتي.\n${hotline.descriptionAr}'
          : 'رقم ${hotline.nameAr} هو: ${hotline.number}.\n${hotline.descriptionAr}\nدوس على الزرار اللي تحت للاتصال على طول.';
      final replyEn = wantsCall
          ? 'Opening dialer for ${hotline.nameEn} (${hotline.number}).\n${hotline.descriptionEn}'
          : '${hotline.nameEn} hotline is ${hotline.number}.\n${hotline.descriptionEn}';

      return AIResponse(
        intent: hotline.isEmergency
            ? AIIntentType.emergency
            : AIIntentType.egyptGuide,
        replyText: isEnglish ? replyEn : replyAr,
        spokenText: isEnglish
            ? (wantsCall
                ? 'Dialing ${hotline.nameEn} at ${hotline.number}.'
                : '${hotline.nameEn} number is ${hotline.number}. ${hotline.descriptionEn}')
            : (wantsCall
                ? 'حاضر، بتصل بـ ${hotline.nameAr} على رقم ${hotline.number}.'
                : 'رقم ${hotline.nameAr} هو ${hotline.number}. ${hotline.descriptionAr}'),
        primaryAction: wantsCall ? callAction : null,
        quickActions: [
          callAction,
          const AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح دليلك في مصر',
            labelEn: 'Open Egypt Guide',
            route: EgyptGuidePage.routeName,
            iconName: 'guide',
          ),
        ],
        followUpSuggestions: isEnglish
            ? const ['Show all official hotlines', 'Open Egypt Guide']
            : const ['اعرض كل الأرقام الرسمية', 'افتح دليلك في مصر'],
        isEnglish: isEnglish,
      );
    }

    return null;
  }

  /// Answers offline questions about Egypt's disability rights, services,
  /// Integrated Services Card, adapted cars, Law 10/2018, and accessible transit.
  static AIResponse? matchGuideQuestion(
    String normalizedQuery, {
    required bool isEnglish,
  }) {
    bool any(List<String> words) =>
        words.any((w) => normalizedQuery.contains(ArabicNormalizer.normalize(w)));

    // 1. Integrated Services Card
    if (any([
      'بطاقه الخدمات',
      'الخدمات المتكامله',
      'كارت الخدمات',
      'كارت الاعاقه',
      'كارنيه الاعاقه',
      'integrated services card',
      'disability card',
    ])) {
      const ar = 'بطاقة الخدمات المتكاملة — خطوات الاستخراج:\n'
          '1. حجز موعد الكشف الطبي المميكن عبر موقع المجالس الطبية المتخصصة.\n'
          '2. التوجه بالبطاقة الشخصية والتقارير الطبية الحديثة لإجراء الكشف.\n'
          '3. بعد القبول الطبي، حجز موعد التقييم الوظيفي في مكتب التأهيل الاجتماعي التابع لوزارة التضامن.\n\n'
          'أهم المزايا:\n'
          '• خصومات المترو والقطارات والمواصلات العامة.\n'
          '• الجمع بين معاشين والتأمين الصحي الشامل.\n'
          '• التعيين ضمن نسبة 5% وتسهيلات الإسكان والجامعات.\n'
          '• دخول مجاني أو مخفض للمتاحف والأماكن الأثرية الحكومية.';
      const en = 'Integrated Services Card (Egypt) — How to apply:\n'
          '1. Book a medical committee exam via the Specialized Medical Councils portal.\n'
          '2. Bring your National ID and recent medical reports.\n'
          '3. After approval, book your functional assessment at your Ministry of Social Solidarity rehab office.\n\n'
          'Key benefits: Metro & railway discounts, pension & health insurance support, 5% employment quota, and free/reduced museum entry.';
      return AIResponse(
        intent: AIIntentType.egyptGuide,
        replyText: isEnglish ? en : ar,
        spokenText: isEnglish
            ? 'To get Egypt\'s Integrated Services Card: first book the medical exam online, attend with your ID and reports, then complete the functional assessment at the Ministry of Social Solidarity office. You can also call 16439.'
            : 'عشان تستخرج بطاقة الخدمات المتكاملة: أول خطوة تحجز الكشف الطبي المميكن أونلاين، وتروح بالبطاقة والتقارير الطبية، وبعد ما يتقبل بتكمل التقييم الوظيفي في مكتب التأهيل التابع لوزارة التضامن. ولو محتاج أي استفسار كلّم الخط الساخن 16439.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.openUrl,
            labelAr: 'فتح بوابة وزارة التضامن',
            labelEn: 'Open Ministry Portal',
            url: mossPortalUrl,
            iconName: 'link',
          ),
          AssistantAction(
            type: AssistantActionType.callPhone,
            labelAr: 'اتصال بوزارة التضامن (16439)',
            labelEn: 'Call Ministry (16439)',
            phoneNumber: '16439',
            iconName: 'phone',
          ),
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح دليل مصر الكامل',
            labelEn: 'Open Full Egypt Guide',
            route: EgyptGuidePage.routeName,
            iconName: 'guide',
          ),
        ],
        followUpSuggestions: isEnglish
            ? const [
                'Tell me about adapted vehicles',
                'What are my rights in Law 10 of 2018?',
                'Which Cairo Metro lines are accessible?',
              ]
            : const [
                'تفاصيل السيارات المجهزة والإعفاء الجمركي',
                'إيه حقوقي في قانون 10 لسنة 2018؟',
                'إيه خطوط المترو المجهزة؟',
              ],
        isEnglish: isEnglish,
      );
    }

    // 2. Adapted Vehicles & Customs Exemption
    if (any([
      'سياره مجهزه',
      'السيارات المجهزه',
      'عربيه معاقين',
      'عربيات المعاقين',
      'اعفاء جمركي',
      'جمرك العربيه',
      'رخصه قياده',
      'adapted vehicle',
      'adapted car',
      'customs',
    ])) {
      const ar = 'السيارات المجهزة ورخصة القيادة في مصر:\n'
          '• يشترط وجود بطاقة الخدمات المتكاملة سارية.\n'
          '• حجز كشف طبي خاص بالسيارات المجهزة لدى المجالس الطبية المتخصصة لتحديد نوع التجهيز (يدوي / أوتوماتيك / بمرافق).\n'
          '• التقديم بالقرار الطبي وبطاقة الخدمات في المرور والجمارك وفق الضوابط السارية.';
      const en = 'Adapted Vehicles & Special Driving License in Egypt:\n'
          '• Requires a valid Integrated Services Card.\n'
          '• Book a dedicated adapted-vehicle medical exam via the Specialized Medical Councils to determine required modifications.\n'
          '• Submit the medical approval and card to Traffic & Customs authorities per active regulations.';
      return AIResponse(
        intent: AIIntentType.egyptGuide,
        replyText: isEnglish ? en : ar,
        spokenText: isEnglish
            ? 'For an adapted vehicle in Egypt, you need a valid Integrated Services Card, then book a special medical exam through the Specialized Medical Councils before applying at Traffic and Customs.'
            : 'عشان تقدم على عربية مجهزة في مصر، لازم يكون معاك بطاقة خدمات متكاملة سارية، وبعدها تحجز كشف طبي خاص بالسيارات المجهزة في المجالس الطبية المتخصصة قبل ما تقدم في المرور والجمارك.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح دليل مصر الكامل',
            labelEn: 'Open Full Egypt Guide',
            route: EgyptGuidePage.routeName,
            iconName: 'guide',
          ),
          AssistantAction(
            type: AssistantActionType.callPhone,
            labelAr: 'اتصال بوزارة التضامن (16439)',
            labelEn: 'Call Ministry (16439)',
            phoneNumber: '16439',
            iconName: 'phone',
          ),
        ],
        followUpSuggestions: isEnglish
            ? const ['How to get Integrated Services Card?', 'Law 10 of 2018 rights']
            : const ['خطوات استخراج بطاقة الخدمات المتكاملة', 'حقوقي في قانون 10 لسنة 2018'],
        isEnglish: isEnglish,
      );
    }

    // 3. Law No. 10 of 2018 & Rights
    if (any([
      'قانون 10',
      'قانون رقم 10',
      'حقوقي',
      'حقوق ذوي الاعاقه',
      'نسبه 5',
      'ساعه عمل',
      'الدمج',
      'law 10',
      'my rights',
      'disability rights',
      'employment quota',
    ])) {
      const ar = 'أهم حقوقك في قانون رقم 10 لسنة 2018 بمصر:\n'
          '• إلزام الجهات الحكومية والمنشآت العامة بالكود الهندسي للإتاحة (منحدرات، مصاعد، حمامات مهيأة).\n'
          '• تخصيص نسبة 5% من الوظائف في المنشآت التي تضم 20 عاملاً فأكثر.\n'
          '• تخفيض ساعات العمل ساعة يومياً مدفوعة الأجر.\n'
          '• الحق في التعليم الدامج وتيسيرات الامتحانات.\n'
          '• يمكنك الإبلاغ عن أي مخالفة عبر الخط الساخن للمجلس القومي للأشخاص ذوي الإعاقة (16736).';
      const en = 'Your Rights Under Egypt Law No. 10 of 2018:\n'
          '• Mandatory architectural accessibility standards (ramps, elevators, accessible restrooms) in public buildings.\n'
          '• 5% employment quota in workplaces with 20+ employees.\n'
          '• One paid reduced working hour daily.\n'
          '• Inclusive education and exam accommodations.\n'
          '• Report violations via the National Council hotline: 16736.';
      return AIResponse(
        intent: AIIntentType.egyptGuide,
        replyText: isEnglish ? en : ar,
        spokenText: isEnglish
            ? 'Under Egypt Law 10 of 2018, public buildings must meet accessibility standards, workplaces have a 5 percent employment quota plus one paid reduced work hour daily. You can report violations at 16736.'
            : 'قانون 10 لسنة 2018 بيضمنلك الإتاحة الهندسية زي الرامب والأسانسير في المنشآت العامة، ونسبة 5 في المية تعيين، وساعة تخفيض يومياً مدفوعة الأجر. ولو قابلتك أي مخالفة تقدر تبلغ المجلس القومي على 16736.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.callPhone,
            labelAr: 'المجلس القومي للإعاقة (16736)',
            labelEn: 'Call Disability Council (16736)',
            phoneNumber: '16736',
            iconName: 'phone',
          ),
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح دليلك في مصر',
            labelEn: 'Open Egypt Guide',
            route: EgyptGuidePage.routeName,
            iconName: 'guide',
          ),
        ],
        followUpSuggestions: isEnglish
            ? const ['Integrated Services Card steps', 'Report an accessibility barrier']
            : const ['خطوات بطاقة الخدمات المتكاملة', 'أبلغ عن عائق الآن'],
        isEnglish: isEnglish,
      );
    }

    // 4. Cairo Metro & Public Transit tips
    if (any([
      'مترو',
      'الخط الثالث',
      'تذكره المترو',
      'خصم المواصلات',
      'القطار الكهربائي',
      'cairo metro',
      'public transit',
      'transit discount',
      'lrt',
    ]) &&
        !normalizedQuery.contains('بشتيل') &&
        !normalizedQuery.contains('اقرب محط')) {
      const ar = 'المواصلات العامة والمترو في مصر:\n'
          '• الخط الثالث لمترو الأنفاق (الأخضر)، القطار الكهربائي الخفيف (LRT)، ومحطة قطارات بشتيل مجهزة بالكامل بمصاعد ومنحدرات ومسارات للكراسي.\n'
          '• حاملو بطاقة الخدمات المتكاملة يحصلون على تذاكر واشتراكات مخفضة في المترو والقطارات.\n'
          '• قبل النزول لمحطات الخط الأول أو الثاني القديمة، يفضل مراجعة البلاغات الحديثة على خريطة ONEWAY للتأكد من عمل المصاعد.';
      const en = 'Cairo Metro & Accessible Public Transit:\n'
          '• Cairo Metro Line 3 (Green Line), LRT stations, and Bashtil Railway Station have elevators, ramps, and wide gates.\n'
          '• Integrated Services Card holders get reduced fares and passes on Metro and Railways.\n'
          '• Always check recent community reports on ONEWAY before using older Line 1 or 2 stations.';
      return AIResponse(
        intent: AIIntentType.egyptGuide,
        replyText: isEnglish ? en : ar,
        spokenText: isEnglish
            ? 'Cairo Metro Line 3, the LRT, and Bashtil Station are equipped with elevators and ramps, and Integrated Services Card holders get reduced fares.'
            : 'الخط التالت للمترو والقطار الكهربائي ومحطة بشتيل مجهزين بأسانسيرات ومنحدرات للكراسي، ومع بطاقة الخدمات المتكاملة ليك تخفيض على التذاكر والاشتراكات.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'عرض محطات المواصلات على الخريطة',
            labelEn: 'View Transit on Map',
            route: 'ExploreMap',
            routeParams: {'category': 'مواصلات'},
            iconName: 'map',
          ),
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح دليلك في مصر',
            labelEn: 'Open Egypt Guide',
            route: EgyptGuidePage.routeName,
            iconName: 'guide',
          ),
        ],
        followUpSuggestions: isEnglish
            ? const ['Find accessible transit stations', 'Integrated Services Card benefits']
            : const ['ابحث عن محطة قطار مجهزة', 'مزايا بطاقة الخدمات المتكاملة'],
        isEnglish: isEnglish,
      );
    }

    return null;
  }
}
