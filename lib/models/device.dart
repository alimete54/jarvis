enum DeviceType { light, climate, security, generator, lab, arcReactor, door }
enum DeviceStatus { on, off, standby, error }

class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  DeviceStatus status;
  double value;
  bool isLocked;

  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.off,
    this.value = 0.0,
    this.isLocked = false,
  });

  String get statusText {
    switch (status) {
      case DeviceStatus.on: return 'AÇIK';
      case DeviceStatus.off: return 'KAPALI';
      case DeviceStatus.standby: return 'BEKLEME';
      case DeviceStatus.error: return 'HATA';
    }
  }

  IconType get iconType {
    switch (type) {
      case DeviceType.light: return IconType.light;
      case DeviceType.climate: return IconType.climate;
      case DeviceType.security: return IconType.security;
      case DeviceType.generator: return IconType.generator;
      case DeviceType.lab: return IconType.lab;
      case DeviceType.arcReactor: return IconType.arcReactor;
      case DeviceType.door: return IconType.door;
    }
  }
}

enum IconType { light, climate, security, generator, lab, arcReactor, door }
