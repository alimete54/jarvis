import '../models/device.dart';

class HomeKitService {
  final List<SmartDevice> _devices = [];

  HomeKitService() {
    _initDevices();
  }

  void _initDevices() {
    _devices.addAll([
      SmartDevice(id: 'light_1', name: 'Ana Salon Işıkları', type: DeviceType.light, status: DeviceStatus.on),
      SmartDevice(id: 'light_2', name: 'Laboratuvar Işıkları', type: DeviceType.light, status: DeviceStatus.on),
      SmartDevice(id: 'climate_1', name: 'Malikane İklim Kontrol', type: DeviceType.climate, value: 22.0),
      SmartDevice(id: 'security_1', name: 'Güvenlik Sistemi', type: DeviceType.security, status: DeviceStatus.on, isLocked: true),
      SmartDevice(id: 'gen_1', name: 'Acil Durum Jeneratörü', type: DeviceType.generator, status: DeviceStatus.standby),
      SmartDevice(id: 'lab_1', name: 'Laboratuvar Ekipmanları', type: DeviceType.lab, status: DeviceStatus.on),
      SmartDevice(id: 'arc_1', name: 'Ark Reaktör Şarj Ünitesi', type: DeviceType.arcReactor, status: DeviceStatus.standby, value: 85.0),
      SmartDevice(id: 'door_1', name: 'Zırh Kabini', type: DeviceType.door, isLocked: true),
    ]);
  }

  List<SmartDevice> get devices => List.unmodifiable(_devices);
  List<SmartDevice> get activeDevices => _devices.where((d) => d.status == DeviceStatus.on).toList();

  void toggleDevice(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.status = device.status == DeviceStatus.on ? DeviceStatus.off : DeviceStatus.on;
  }

  void setDeviceValue(String id, double value) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.value = value;
  }

  void lockDevice(String id, bool locked) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.isLocked = locked;
  }

  SmartDevice? getDevice(String id) {
    try {
      return _devices.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
