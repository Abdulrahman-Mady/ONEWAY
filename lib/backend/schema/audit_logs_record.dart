import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AuditLogsRecord extends FirestoreRecord {
  AuditLogsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "user_id" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "action" field.
  String? _action;
  String get action => _action ?? '';
  bool hasAction() => _action != null;

  // "details" field.
  String? _details;
  String get details => _details ?? '';
  bool hasDetails() => _details != null;

  // "target_collection" field.
  String? _targetCollection;
  String get targetCollection => _targetCollection ?? '';
  bool hasTargetCollection() => _targetCollection != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  void _initializeFields() {
    _userId = snapshotData['user_id'] as String?;
    _action = snapshotData['action'] as String?;
    _details = snapshotData['details'] as String?;
    _targetCollection = snapshotData['target_collection'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('auditLogs');

  static Stream<AuditLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AuditLogsRecord.fromSnapshot(s));

  static Future<AuditLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AuditLogsRecord.fromSnapshot(s));

  static AuditLogsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AuditLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AuditLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AuditLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AuditLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AuditLogsRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createAuditLogsRecordData({
  String? userId,
  String? action,
  String? details,
  String? targetCollection,
  DateTime? timestamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_id': userId,
      'action': action,
      'details': details,
      'target_collection': targetCollection,
      'timestamp': timestamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class AuditLogsRecordDocumentEquality implements Equality<AuditLogsRecord> {
  const AuditLogsRecordDocumentEquality();

  @override
  bool equals(AuditLogsRecord? e1, AuditLogsRecord? e2) {
    return e1?.userId == e2?.userId && e1?.action == e2?.action;
  }

  @override
  int hash(AuditLogsRecord? e) =>
      const ListEquality().hash([e?.userId, e?.action]);

  @override
  bool isValidKey(Object? o) => o is AuditLogsRecord;
}
