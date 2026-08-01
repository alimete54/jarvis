const List<Map<String, dynamic>> toolDefinitions = [
  {
    'name': 'set_flashlight',
    'description': 'Telefonun el fenerini (torch) açar veya kapatır.',
    'parameters': {'type': 'object', 'properties': {'on': {'type': 'boolean'}}, 'required': ['on']},
  },
  {
    'name': 'set_brightness',
    'description': 'Ekran parlaklığını ayarlar. Değer 0.0-1.0 arası (0.5 = %50).',
    'parameters': {
      'type': 'object',
      'properties': {'level': {'type': 'number', 'minimum': 0, 'maximum': 1}},
      'required': ['level'],
    },
  },
  {
    'name': 'get_battery',
    'description': 'Pil seviyesini ve şarj durumunu döndürür.',
    'parameters': {'type': 'object', 'properties': {}},
  },
  {
    'name': 'take_photo',
    'description': 'Kamera ile fotoğraf çeker ve görüntüyü analiz eder (Jarvis ne gördüğünü anlatır).',
    'parameters': {
      'type': 'object',
      'properties': {'question': {'type': 'string', 'description': 'Fotoğraf hakkında soru, örn: "Ne görüyorsun?"'}},
    },
  },
  {
    'name': 'set_timer',
    'description': 'X dakika sonra bildirim ile hatırlatır (zamanlayıcı/çalar saat).',
    'parameters': {
      'type': 'object',
      'properties': {'minutes': {'type': 'integer', 'minimum': 1}, 'label': {'type': 'string'}},
      'required': ['minutes'],
    },
  },
  {
    'name': 'schedule_reminder',
    'description': 'Belirtilen tarihte/saatte (ISO 8601, örn 2026-08-01T14:30:00) hatırlatıcı oluşturur.',
    'parameters': {
      'type': 'object',
      'properties': {'when': {'type': 'string'}, 'text': {'type': 'string'}},
      'required': ['when', 'text'],
    },
  },
  {
    'name': 'add_calendar_event',
    'description': 'Takvime etkinlik ekler. Başlangıç ve bitiş ISO 8601 formatında.',
    'parameters': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'start': {'type': 'string'},
        'end': {'type': 'string'},
        'location': {'type': 'string'},
      },
      'required': ['title', 'start'],
    },
  },
  {
    'name': 'search_contacts',
    'description': 'Rehberde kişi arar. Sorgu isim olabilir.',
    'parameters': {
      'type': 'object',
      'properties': {'query': {'type': 'string'}},
      'required': ['query'],
    },
  },
  {
    'name': 'call_phone',
    'description': 'Bir telefon numarasını arar (numara +[ülke kodu] formatında). Arama onayı telefonda gösterilir.',
    'parameters': {
      'type': 'object',
      'properties': {'number': {'type': 'string'}, 'name': {'type': 'string'}},
      'required': ['number'],
    },
  },
  {
    'name': 'send_sms',
    'description': 'Bir telefon numarasına SMS yazar ve Mesajlar uygulamasını açar (kullanıcı "gönder"e basar).',
    'parameters': {
      'type': 'object',
      'properties': {'number': {'type': 'string'}, 'message': {'type': 'string'}},
      'required': ['number', 'message'],
    },
  },
  {
    'name': 'send_email',
    'description': 'E-posta taslağı oluşturur ve mail uygulamasını açar.',
    'parameters': {
      'type': 'object',
      'properties': {'to': {'type': 'string'}, 'subject': {'type': 'string'}, 'body': {'type': 'string'}},
      'required': ['to'],
    },
  },
  {
    'name': 'get_location',
    'description': 'Cihazın güncel konumunu (enlem, boylam) döndürür.',
    'parameters': {'type': 'object', 'properties': {}},
  },
  {
    'name': 'get_weather',
    'description': 'Bir konum için güncel hava durumunu döndürür (derece, rüzgar).',
    'parameters': {
      'type': 'object',
      'properties': {
        'latitude': {'type': 'number'},
        'longitude': {'type': 'number'},
        'city': {'type': 'string'},
      },
    },
  },
  {
    'name': 'copy_to_clipboard',
    'description': 'Metni panoya kopyalar.',
    'parameters': {'type': 'object', 'properties': {'text': {'type': 'string'}}, 'required': ['text']},
  },
  {
    'name': 'open_url',
    'description': 'Bir web sayfasını veya uygulama linkini açar.',
    'parameters': {'type': 'object', 'properties': {'url': {'type': 'string'}}, 'required': ['url']},
  },
];
