import 'package:cloud_firestore/cloud_firestore.dart';

/// Seed initial curated Egyptian accessible places into Firestore.
class OnewayDataSeeder {
  static final List<Map<String, dynamic>> initialPlaces = [
    {
      'id': 'nmec_cairo',
      'name': 'متحف القومي للحضارة المصرية (NMEC)',
      'category': 'سياحة وثقافة',
      'description':
          'صرح ثقافي عالمي مصمم بالكامل ليكون صديقاً لمستخدمي الكراسي المتحركة؛ ممرات انسيابية، مصاعد لكافة الطوابق وقاعة المومياوات، ودورات مياه مجهزة.',
      'photo_url':
          'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'عين الصيرة، الفسطاط، مصر القديمة',
      'governorate': 'القاهرة',
      'city': 'الفسطاط',
      'location': const GeoPoint(30.0076, 31.2486),
      'phone_number': '+20227412273',
      'website': 'https://nmec.gov.eg',
      'opening_hours': '09:00 ص - 05:00 م (يومياً)',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع جداً (أكثر من 180 سم)',
        'entranceObstacles': 'لا يوجد عوائق - بوابات إلكترونية مجهزة',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 4.9,
    },
    {
      'id': 'kasr_alainy_french',
      'name': 'مستشفى قصر العيني الفرنساوي',
      'category': 'طبي ومستشفيات',
      'description':
          'مستشفى جامعي علاجي مجهز بمنحدرات دخول رئيسية وإسعافية، ومصاعد طبية تسع الكراسي المتحركة والأسِرة، مع دورات مياه مجهزة في الاستقبال.',
      'photo_url':
          'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'شارع قصر العيني، منيل الروضة',
      'governorate': 'القاهرة',
      'city': 'منيل الروضة',
      'location': const GeoPoint(30.0308, 31.2294),
      'phone_number': '+20223654060',
      'website': 'https://kasralainy.edu.eg',
      'opening_hours': 'طوارئ 24 ساعة',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع (أكثر من 160 سم)',
        'entranceObstacles': 'منحدر متدرج عند مدخل الاستقبال الرئيسي',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 4.8,
    },
    {
      'id': 'mall_of_egypt',
      'name': 'مول مصر (Mall of Egypt)',
      'category': 'تسوق ومراكز تجارية',
      'description':
          'مركز تجاري وترفيهي متكامل يطبق أعلى معايير سهولة الوصول؛ مداخل ممهدة بالكامل، مواقف سيارات خاصة قريبة من البوابات، وحمامات مجهزة بكل دور.',
      'photo_url':
          'https://images.unsplash.com/photo-1519567241046-7f570eee3ce6?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1519567241046-7f570eee3ce6?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'طريق الواحات، مدينة 6 أكتوبر',
      'governorate': 'الجيزة',
      'city': '6 أكتوبر',
      'location': const GeoPoint(29.9722, 31.0163),
      'phone_number': '+20235390000',
      'website': 'https://mallofegypt.com',
      'opening_hours': '10:00 ص - 11:00 م',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع جداً',
        'entranceObstacles': 'لا يوجد عوائق، أبواب منزلقة أوتوماتيكية',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 4.9,
    },
    {
      'id': 'auc_new_cairo',
      'name': 'الجامعة الأمريكية بالقاهرة (AUC)',
      'category': 'تعليم وجامعات',
      'description':
          'حرم جامعي مطابق لمعايير ADA الدولية للإتاحة؛ جميع المباني الإدارية والتعليمية مزودة بمصاعد ومنحدرات وممرات فسيحة ودورات مياه متوافقة.',
      'photo_url':
          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'شارع التسعين الجنوبي، التجمع الخامس',
      'governorate': 'القاهرة',
      'city': 'القاهرة الجديدة',
      'location': const GeoPoint(30.0194, 31.5003),
      'phone_number': '+20226151000',
      'website': 'https://aucegypt.edu',
      'opening_hours': '08:30 ص - 05:00 م',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع ومطابق للأكواد الدولية',
        'entranceObstacles': 'لا يوجد عوائق',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 5.0,
    },
    {
      'id': 'bashtil_station',
      'name': 'محطة قطارات صعيد مصر (بشتيل)',
      'category': 'مواصلات ونقل',
      'description':
          'محطة قطارات ذكية ونموذجية افتتحت عام 2024، مزودة بمسارات إتاحة حركية، مصاعد كهربائية للأرصفة، بوابات تذاكر عريضة، وحمامات مجهزة لذوي الإعاقة.',
      'photo_url':
          'https://images.unsplash.com/photo-1474487548417-781cb71495f3?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1474487548417-781cb71495f3?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'محور الفريق كمال عامر، بشتيل',
      'governorate': 'الجيزة',
      'city': 'بشتيل',
      'location': const GeoPoint(30.0768, 31.1983),
      'phone_number': '+20237741122',
      'website': 'https://enr.gov.eg',
      'opening_hours': '24 ساعة',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع جداً',
        'entranceObstacles': 'بوابات عبور مخصصة للكراسي المتحركة',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 4.8,
    },
    {
      'id': 'citystars_cairo',
      'name': 'سيتي ستارز مول (Citystars)',
      'category': 'تسوق ومراكز تجارية',
      'description':
          'مجمع تجاري يضم مصاعد متعددة وخدمة كراسي متحركة عند الطلب من الاستقبال؛ بعض الأبواب الدوارة تتطلب الدخول من الباب الجانبي المخصص.',
      'photo_url':
          'https://images.unsplash.com/photo-1567449303078-57ad995bd301?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1567449303078-57ad995bd301?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'شارع عمر بن الخطاب، مساكن المهندسين، مدينة نصر',
      'governorate': 'القاهرة',
      'city': 'مدينة نصر',
      'location': const GeoPoint(30.0732, 31.3456),
      'phone_number': '+20224800555',
      'website': 'https://citystarsheliopolis.com.eg',
      'opening_hours': '10:00 ص - 12:00 ص',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع',
        'entranceObstacles': 'الدخول عبر الأبواب الجانبية للأبواب الدوارة',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 4.6,
    },
    {
      'id': 'greater_cairo_library',
      'name': 'مكتبة القاهرة الكبرى (الزمالك)',
      'category': 'سياحة وثقافة',
      'description':
          'قصر تاريخي به مدخل رئيسي يتضمن درجات سلم؛ يوجد منحدر جانبي للدور الأرضي والحديقة، ولكن الأدوار العلوية تفتقر للمصعد لطبيعة المبنى الأثري.',
      'photo_url':
          'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=800&q=80'
      ],
      'address': '15 شارع محمد مظهر، الزمالك',
      'governorate': 'القاهرة',
      'city': 'الزمالك',
      'location': const GeoPoint(30.0631, 31.2212),
      'phone_number': '+20227362278',
      'website': '',
      'opening_hours': '09:00 ص - 04:00 م (الجمعة مغلق)',
      'accessibility_features': {
        'wheelchairEntrance': false,
        'ramp': true,
        'suitableElevator': false,
        'accessibleRestroom': false,
        'accessibleParking': false,
        'corridorWidth': 'متوسط (طراز أثري)',
        'entranceObstacles':
            'درجات رخامية بالمدخل الرئيسي؛ المنحدر متاح عبر البوابة الجانبية',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 3.6,
    },
    {
      'id': 'dar_al_fouad_october',
      'name': 'مستشفى دار الفؤاد (6 أكتوبر)',
      'category': 'طبي ومستشفيات',
      'description':
          'مستشفى تخصصي بمعايير دولية، منحدرات ممهدة في كل المداخل، مصاعد طبية فسيحة، ممرات مجهزة بدرابزين أمان، ودورات مياه ملائمة للكراسي المتحركة.',
      'photo_url':
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
      'photos': [
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80'
      ],
      'address': 'امتداد محور 26 يوليو، الحي المتميز، 6 أكتوبر',
      'governorate': 'الجيزة',
      'city': '6 أكتوبر',
      'location': const GeoPoint(29.9882, 30.9577),
      'phone_number': '+20238356030',
      'website': 'https://daralfouad.org',
      'opening_hours': 'طوارئ 24 ساعة',
      'accessibility_features': {
        'wheelchairEntrance': true,
        'ramp': true,
        'suitableElevator': true,
        'accessibleRestroom': true,
        'accessibleParking': true,
        'corridorWidth': 'واسع جداً ومجهز بمقابض جدارية',
        'entranceObstacles': 'لا يوجد عوائق',
      },
      'verification_status': 'verified',
      'verified_by': 'فريق ONEWAY الميداني',
      'rating': 4.9,
    },
  ];

  /// Seeds all initial places into the 'places' collection in Firestore.
  static Future<int> seedPlaces() async {
    final firestore = FirebaseFirestore.instance;
    int count = 0;

    for (final place in initialPlaces) {
      final docId = place['id'] as String;
      final copy = Map<String, dynamic>.from(place);
      copy.remove('id');
      copy['last_verified_at'] = FieldValue.serverTimestamp();

      await firestore
          .collection('places')
          .doc(docId)
          .set(copy, SetOptions(merge: true));
      count++;
    }

    return count;
  }
}
