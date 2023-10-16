import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:sentry/sentry.dart';
import 'sentry_hive_interface.dart';

import 'default_compaction_strategy.dart';
import 'default_key_comparator.dart';

///
@experimental
class SentryHiveImpl implements SentryHiveInterface {

  @internal
  // ignore: public_member_api_docs
  static const dbOp = 'db';

  @internal
  // ignore: public_member_api_docs
  static const dbSystemKey = 'db.system';
  @internal
  // ignore: public_member_api_docs
  static const dbSystem = 'sqlite';

  @internal
  // ignore: public_member_api_docs
  static const dbNameKey = 'db.name';

  final HiveInterface _hive;
  Hub _hub = HubAdapter();

  ///
  SentryHiveImpl(this._hive);

  // SentryHiveInterface

  @override
  void setHub(Hub hub) {
    _hub = hub;
  }

  // HiveInterface

  @override
  void init(String? path, {HiveStorageBackendPreference backendPreference = HiveStorageBackendPreference.native}) {
    return Hive.init(path, backendPreference: backendPreference);
  }

  @override
  Box<E> box<E>(String name) {
    return _hive.box(name);
  }

  @override
  Future<bool> boxExists(String name, {String? path}) {
    return _hive.boxExists(name, path: path);
  }

  @override
  Future<void> close() {
    return _hive.close();
  }

  @override
  Future<void> deleteBoxFromDisk(String name, {String? path}) {
    return _hive.deleteBoxFromDisk(name, path: path);
  }

  @override
  Future<void> deleteFromDisk() {
    return _hive.deleteFromDisk();
  }

  @override
  List<int> generateSecureKey() {
    return _hive.generateSecureKey();
  }

  @override
  void ignoreTypeId<T>(int typeId) {
    return _hive.ignoreTypeId<T>(typeId);
  }

  @override
  bool isAdapterRegistered(int typeId) {
    return _hive.isAdapterRegistered(typeId);
  }

  @override
  bool isBoxOpen(String name) {
    return _hive.isBoxOpen(name);
  }

  @override
  LazyBox<E> lazyBox<E>(String name) {
    return _hive.lazyBox(name);
  }

  @override
  Future<Box<E>> openBox<E>(String name, {HiveCipher? encryptionCipher, KeyComparator keyComparator = defaultKeyComparator, CompactionStrategy compactionStrategy = defaultCompactionStrategy, bool crashRecovery = true, String? path, Uint8List? bytes, String? collection, List<int>? encryptionKey}) {
    return _hive.openBox(
      name,
      encryptionCipher: encryptionCipher,
      keyComparator: keyComparator,
      compactionStrategy: compactionStrategy,
      crashRecovery: crashRecovery,
      path: path,
      bytes: bytes,
      collection: collection,
      encryptionKey: encryptionKey,
    );
  }

  @override
  Future<LazyBox<E>> openLazyBox<E>(String name, {HiveCipher? encryptionCipher, KeyComparator keyComparator = defaultKeyComparator, CompactionStrategy compactionStrategy = defaultCompactionStrategy, bool crashRecovery = true, String? path, String? collection, List<int>? encryptionKey}) {
    return _hive.openLazyBox(
      name,
      encryptionCipher: encryptionCipher,
      keyComparator: keyComparator,
      compactionStrategy: compactionStrategy,
      crashRecovery: crashRecovery,
      path: path,
      collection: collection,
      encryptionKey: encryptionKey,
    );
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, {bool internal = false, bool override = false}) {
    return _hive.registerAdapter(adapter, internal: internal, override: override);
  }

  @visibleForTesting
  @override
  void resetAdapters() {
    // ignore: invalid_use_of_visible_for_testing_member
    return _hive.resetAdapters();
  }
}
