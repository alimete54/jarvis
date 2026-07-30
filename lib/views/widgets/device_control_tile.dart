import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/device.dart';

class DeviceControlTile extends StatelessWidget {
  final SmartDevice device;
  final VoidCallback? onToggle;

  const DeviceControlTile({super.key, required this.device, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: JARVISTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.status == DeviceStatus.on
              ? JARVISTheme.primary.withOpacity(0.2)
              : JARVISTheme.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: device.status == DeviceStatus.on
                  ? JARVISTheme.primary.withOpacity(0.15)
                  : JARVISTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconForType(device.iconType),
              color: device.status == DeviceStatus.on ? JARVISTheme.primary : JARVISTheme.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(device.statusText, style: TextStyle(
                  color: device.status == DeviceStatus.on ? JARVISTheme.success : JARVISTheme.textSecondary,
                  fontSize: 11,
                )),
              ],
            ),
          ),
          if (device.type == DeviceType.climate)
            Text('${device.value.toStringAsFixed(0)}°C', style: const TextStyle(color: JARVISTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
          if (device.type == DeviceType.arcReactor)
            Text('%${device.value.toStringAsFixed(0)}', style: const TextStyle(color: JARVISTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: device.status == DeviceStatus.on
                    ? JARVISTheme.primary.withOpacity(0.3)
                    : JARVISTheme.surfaceLight,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: device.status == DeviceStatus.on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: device.status == DeviceStatus.on ? JARVISTheme.primary : JARVISTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(IconType type) {
    switch (type) {
      case IconType.light: return Icons.lightbulb_outline;
      case IconType.climate: return Icons.ac_unit;
      case IconType.security: return Icons.videocam_outlined;
      case IconType.generator: return Icons.electrical_services;
      case IconType.lab: return Icons.science_outlined;
      case IconType.arcReactor: return Icons.bolt;
      case IconType.door: return Icons.door_front_door_outlined;
    }
  }
}
