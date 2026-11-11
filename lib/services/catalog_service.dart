import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// كتالوج الموديلات والشركات — يُحدَّث تلقائياً عند إدخال موديل جديد
class CatalogService {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  static const _keyModels = 'catalog_models';
  static const _keyManufacturers = 'catalog_manufacturers';
  static const _keyItemNames = 'catalog_item_names';

  final Set<String> models = {};
  final Set<String> manufacturers = {};
  final Set<String> itemNames = {};

  /// قيم أولية شائعة
  static const List<String> defaultManufacturers = [
    'HP',
    'Dell',
    'Lenovo',
    'Cisco',
    'Huawei',
    'MikroTik',
    'Ubiquiti',
    'Samsung',
    'Canon',
    'Epson',
    'APC',
    'TP-Link',
    'D-Link',
    'Microsoft',
    'Apple',
  ];

  static const List<String> defaultModels = [
    'OptiPlex 7090',
    'Latitude 5520',
    'ThinkCentre M90',
    'ProBook 450 G8',
    'Catalyst 2960',
    'ISR 4331',
    'RB4011',
    'UniFi AP AC Pro',
    'LaserJet Pro M404',
    'Smart-UPS 1500',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    models
      ..clear()
      ..addAll(defaultModels)
      ..addAll(prefs.getStringList(_keyModels) ?? []);
    manufacturers
      ..clear()
      ..addAll(defaultManufacturers)
      ..addAll(prefs.getStringList(_keyManufacturers) ?? []);
    itemNames
      ..clear()
      ..addAll(prefs.getStringList(_keyItemNames) ?? []);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyModels, models.toList()..sort());
    await prefs.setStringList(_keyManufacturers, manufacturers.toList()..sort());
    await prefs.setStringList(_keyItemNames, itemNames.toList()..sort());
  }

  /// عند حفظ جهاز: إضافة الشركة والموديل للكتالوج
  Future<void> learnFromDevice(Device d) async {
    var changed = false;
    if (d.model.trim().isNotEmpty && models.add(d.model.trim())) changed = true;
    if (d.manufacturer.trim().isNotEmpty && manufacturers.add(d.manufacturer.trim())) {
      changed = true;
    }
    if (changed) await _persist();
  }

  /// عند حفظ مادة عهدة
  Future<void> learnFromItemName(String name) async {
    if (name.trim().isEmpty) return;
    if (itemNames.add(name.trim())) await _persist();
  }

  /// مزامنة من قائمة أجهزة موجودة
  Future<void> syncFromDevices(List<Device> devices) async {
    var changed = false;
    for (final d in devices) {
      if (d.model.trim().isNotEmpty && models.add(d.model.trim())) changed = true;
      if (d.manufacturer.trim().isNotEmpty && manufacturers.add(d.manufacturer.trim())) {
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  List<String> suggestModels(String query) {
    final q = query.trim().toLowerCase();
    final list = models.toList()..sort();
    if (q.isEmpty) return list.take(20).toList();
    return list.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }

  List<String> suggestManufacturers(String query) {
    final q = query.trim().toLowerCase();
    final list = manufacturers.toList()..sort();
    if (q.isEmpty) return list.take(20).toList();
    return list.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }

  List<String> suggestItemNames(String query) {
    final q = query.trim().toLowerCase();
    final list = itemNames.toList()..sort();
    if (q.isEmpty) return list.take(20).toList();
    return list.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }
}
