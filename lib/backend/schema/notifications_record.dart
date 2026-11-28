import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class NotificationsRecord extends FirestoreRecord {
  NotificationsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "body" field.
  String? _body;
  String get body => _body ?? '';
  bool hasBody() => _body != null;

  // "type" field.
  String? _type;
  String get type => _type ?? 'system';
  bool hasType() => _type != null;

  // "is_read" field.
  bool? _isRead;
  bool get isRead => _isRead ?? false;
  bool hasIsRead() => _isRead != null;

  // "report_id" field (links report_status notifications directly to the report).
  String? _reportId;
  String get reportId => _reportId ?? '';
  bool hasReportId() => _reportId != null && _reportId!.isNotEmpty;

  // "business_id" field.
  String? _businessId;
  String get businessId => _businessId ?? '';
  bool hasBusinessId() => _businessId != null && _businessId!.isNotEmpty;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _title = snapshotData['title'] as String?;
    _body = snapshotData['body'] as String?;
    _type = snapshotData['type'] as String?;
    _isRead = snapshotData['is_read'] as bool?;
    _reportId = snapshotData['report_id'] as String?;
    _businessId = snapshotData['business_id'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('notifications');

  static Stream<NotificationsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => NotificationsRecord.fromSnapshot(s));

  static Future<NotificationsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => NotificationsRecord.fromSnapshot(s));

  static NotificationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      NotificationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static NotificationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      NotificationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'NotificationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is NotificationsRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createNotificationsRecordData({
  String? userId,
  String? title,
  String? body,
  String? type,
  bool? isRead,
  String? reportId,
  String? businessId,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'report_id': reportId,
      'business_id': businessId,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class NotificationsRecordDocumentEquality
    implements Equality<NotificationsRecord> {
  const NotificationsRecordDocumentEquality();

  @override
  bool equals(NotificationsRecord? e1, NotificationsRecord? e2) {
    return e1?.userId == e2?.userId && e1?.isRead == e2?.isRead;
  }

  @override
  int hash(NotificationsRecord? e) =>
      const ListEquality().hash([e?.userId, e?.isRead]);

  @override
  bool isValidKey(Object? o) => o is NotificationsRecord;
}
