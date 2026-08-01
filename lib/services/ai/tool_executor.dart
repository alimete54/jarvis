import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Event;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class ToolResult {
  final bool ok;
  final String message;

  const ToolResult(this.ok, this.message);
}

class ToolExecutor {
  static const _torchChannel = MethodChannel('jarvis/torch');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DeviceCalendarPlugin _calendar = DeviceCalendarPlugin();
  final ImagePicker _picker = ImagePicker();

  Future<String> Function(String imagePath, String question)? visionHandler;

  int _notificationId = 1;

  ToolExecutor() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    tzdata.initializeTimeZones();
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<ToolResult> execute(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'set_flashlight':
          return _setFlashlight(args['on'] == true);
        case 'set_brightness':
          return _setBrightness((args['level'] as num).toDouble());
        case 'get_battery':
          return _getBattery();
        case 'take_photo':
          return _takePhoto(args['question'] as String? ?? 'Ne görüyorsun?');
        case 'set_timer':
          return _setTimer((args['minutes'] as num).toInt(), args['label'] as String? ?? 'Zamanlayıcı');
        case 'schedule_reminder':
          return _scheduleReminder(DateTime.parse(args['when'] as String), args['text'] as String);
        case 'add_calendar_event':
          return _addCalendarEvent(args);
        case 'search_contacts':
          return _searchContacts(args['query'] as String? ?? '');
        case 'call_phone':
          return _callPhone(args['number'] as String, args['name'] as String?);
        case 'send_sms':
          return _sendSms(args['number'] as String, args['message'] as String);
        case 'send_email':
          return _sendEmail(args['to'] as String, args['subject'] as String? ?? '', args['body'] as String? ?? '');
        case 'get_location':
          return _getLocation();
        case 'get_weather':
          return _getWeather(
            latitude: (args['latitude'] as num?)?.toDouble(),
            longitude: (args['longitude'] as num?)?.toDouble(),
            city: args['city'] as String?,
          );
        case 'copy_to_clipboard':
          await Clipboard.setData(ClipboardData(text: args['text'] as String));
          return const ToolResult(true, 'Metin panoya kopyalandı.');
        case 'open_url':
          return _openUrl(args['url'] as String);
        default:
          return ToolResult(false, 'Bilinmeyen araç: $name');
      }
    } catch (e) {
      return ToolResult(false, 'Hata: $e');
    }
  }

  Future<ToolResult> _setFlashlight(bool on) async {
    try {
      await _torchChannel.invokeMethod('setTorch', {'on': on});
      return ToolResult(true, on ? 'El feneri açıldı.' : 'El feneri kapatıldı.');
    } on MissingPluginException {
      return const ToolResult(false, 'El feneri bu platformda desteklenmiyor (native build gerekir).');
    }
  }

  Future<ToolResult> _setBrightness(double level) async {
    final clamped = level.clamp(0.0, 1.0);
    try {
      await ScreenBrightness().setScreenBrightness(clamped);
      return ToolResult(true, 'Ekran parlaklığı %${(clamped * 100).round()} yapıldı.');
    } catch (e) {
      return ToolResult(false, 'Parlaklık ayarlanamadı: $e');
    }
  }

  Future<ToolResult> _getBattery() async {
    try {
      final level = await Battery().batteryLevel;
      return ToolResult(true, 'Pil seviyesi: %$level');
    } catch (e) {
      return ToolResult(false, 'Pil bilgisi alınamadı: $e');
    }
  }

  Future<ToolResult> _takePhoto(String question) async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (photo == null) return const ToolResult(false, 'Fotoğraf çekilmedi (iptal edildi).');
    if (visionHandler == null) {
      return ToolResult(true, 'Fotoğraf çekildi ancak görüntü analizi için AI yapılandırılmamış.');
    }
    final analysis = await visionHandler!(photo.path, question);
    return ToolResult(true, analysis);
  }

  Future<ToolResult> _setTimer(int minutes, String label) async {
    final when = DateTime.now().add(Duration(minutes: minutes));
    await _schedule(when, label, 'Zamanlayıcı bitti (${minutes} dk)');
    return ToolResult(true, '$label için $minutes dakikalık zamanlayıcı kuruldu.');
  }

  Future<ToolResult> _scheduleReminder(DateTime when, String text) async {
    if (when.isBefore(DateTime.now())) {
      return const ToolResult(false, 'Geçmiş bir zaman verildi.');
    }
    await _schedule(when, 'Hatırlatıcı', text);
    return ToolResult(true, 'Hatırlatıcı kuruldu: $text — ${when.hour.toString().padLeft(2, "0")}:${when.minute.toString().padLeft(2, "0")}');
  }

  Future<void> _schedule(DateTime when, String title, String body) async {
    final tzLocal = _tzUtc(when.toUtc());
    await _notifications.zonedSchedule(
      _notificationId++,
      title,
      body,
      tzLocal,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'jarvis_channel',
          'JARVIS Bildirimleri',
          channelDescription: 'Zamanlayıcı ve hatırlatıcı bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _tzUtc(DateTime utc) {
    return tz.TZDateTime.from(utc, tz.UTC);
  }

  Future<ToolResult> _addCalendarEvent(Map<String, dynamic> args) async {
    final permission = await _calendar.requestPermissions();
    if (permission.data != true) {
      return const ToolResult(false, 'Takvim izni verilmedi.');
    }
    final calendars = await _calendar.retrieveCalendars();
    final list = calendars.data ?? [];
    if (list.isEmpty) return const ToolResult(false, 'Takvim bulunamadı.');
    final writable = list.firstWhere(
      (c) => c.isReadOnly == false,
      orElse: () => list.first,
    );
    final end = args['end'] != null
        ? DateTime.parse(args['end'] as String)
        : DateTime.parse(args['start'] as String).add(const Duration(hours: 1));
    final result = await _calendar.createOrUpdateEvent(Event(
      writable.id,
      title: args['title'] as String,
      start: _tzOf(DateTime.parse(args['start'] as String)),
      end: _tzOf(end),
      location: args['location'] as String?,
    ));
    if (result?.isSuccess == true) {
      return ToolResult(true, 'Takvime eklendi: ${args['title']}');
    }
    return const ToolResult(false, 'Takvime eklenemedi.');
  }

  tz.TZDateTime _tzOf(DateTime local) {
    return tz.TZDateTime.from(local.toUtc(), tz.UTC);
  }

  Future<ToolResult> _searchContacts(String query) async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return const ToolResult(false, 'Rehber izni verilmedi.');
    }
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final matches = query.isEmpty
        ? contacts
        : contacts
            .where((c) => c.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
    if (matches.isEmpty) {
      return ToolResult(false, '"$query" rehberde bulunamadı.');
    }
    final lines = matches.take(8).map((c) {
      final phone = c.phones.isNotEmpty ? c.phones.first.number : 'telefon yok';
      return '${c.displayName} — $phone';
    }).join('\n');
    return ToolResult(true, 'Bulunan kişiler:\n$lines');
  }

  Future<ToolResult> _callPhone(String number, String? name) async {
    final uri = Uri.parse('tel:$number');
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return ToolResult(true, '${name ?? number} aranıyor... (onay ekranından devam edin)');
    }
    return const ToolResult(false, 'Arama başlatılamadı.');
  }

  Future<ToolResult> _sendSms(String number, String message) async {
    final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(message)}');
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return ToolResult(true, 'Mesaj yazıldı: $number — "Gönder"e basmanız yeterli.');
    }
    return const ToolResult(false, 'Mesaj uygulaması açılamadı.');
  }

  Future<ToolResult> _sendEmail(String to, String subject, String body) async {
    final uri = Uri.parse('mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return ToolResult(true, 'E-posta taslağı hazırlandı: $to');
    }
    return const ToolResult(false, 'E-posta uygulaması açılamadı.');
  }

  Future<ToolResult> _getLocation() async {
    final hasPermission = await Geolocator.checkPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested != LocationPermission.whileInUse &&
          requested != LocationPermission.always) {
        return const ToolResult(false, 'Konum izni verilmedi.');
      }
    }
    final position = await Geolocator.getCurrentPosition();
    return ToolResult(
      true,
      'Konum: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
    );
  }

  Future<ToolResult> _getWeather({double? latitude, double? longitude, String? city}) async {
    if (latitude == null || longitude == null) {
      try {
        final pos = await _getLocation();
        if (!pos.ok) return pos;
        final match = RegExp(r'([-\d.]+), ([-\d.]+)').firstMatch(pos.message);
        if (match != null) {
          latitude = double.parse(match.group(1)!);
          longitude = double.parse(match.group(2)!);
        }
      } catch (_) {}
    }
    if (latitude == null || longitude == null) {
      return const ToolResult(false, 'Konum bilinmiyor, enlem/boylam gerekli.');
    }
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      return ToolResult(false, 'Hava durumu alınamadı (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>;
    final place = city ?? 'Konumunuz';
    final code = _weatherText((current['weather_code'] as num).toInt());
    return ToolResult(
      true,
      '$place: ${current['temperature_2m']}°C, $code, nem %${current['relative_humidity_2m']}, rüzgar ${current['wind_speed_10m']} km/s',
    );
  }

  String _weatherText(int code) {
    if (code == 0) return 'açık';
    if (code <= 3) return 'az bulutlu';
    if (code <= 48) return 'sisli';
    if (code <= 67) return 'yağmurlu';
    if (code <= 77) return 'karlı';
    if (code <= 82) return 'sağanak';
    if (code <= 86) return 'kar sağanaklı';
    if (code <= 99) return 'gök gürültülü';
    return 'bilinmiyor';
  }

  Future<ToolResult> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return const ToolResult(false, 'Geçersiz URL.');
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return ToolResult(true, 'Açıldı: $url');
    }
    return const ToolResult(false, 'Bağlantı açılamadı.');
  }

  void dispose() {
    _notifications.cancelAll();
  }
}
