# J.A.R.V.I.S. — Kişisel AI Asistan (iOS)

Iron Man evreninden esinlenilmiş, **gerçek AI + gerçek telefon kontrolü** yapan Flutter uygulaması. Windows bilgisayardan geliştirilir, bulut build (Codemagic / GitHub Actions) ile iPhone'a kurulur.

## Özellikler

| Kategori | Yapabildikleri |
|---|---|
| **AI** | OpenAI (GPT), Anthropic (Claude), Google Gemini — kullanıcı seçer, API anahtarını kendisi girer |
| **Ses** | On-device konuşma tanıma (ücretsiz), OpenAI Whisper, Gemini ses girişi; sistem TTS veya OpenAI Jarvis sesi (onyx) |
| **Cihaz** | El feneri (native), ekran parlaklığı, pil durumu, kamera ile fotoğraf çekip AI'ya analiz ettirme |
| **Zaman** | Zamanlayıcı (N dk), tarih/saatli hatırlatıcı (yerel bildirim), takvime etkinlik ekleme |
| **İletişim** | Rehber arama, arama başlatma, SMS taslağı, e-posta taslağı (iOS onay ekranlarıyla) |
| **Bilgi** | Konum, hava durumu (Open-Meteo), pano kopyalama, URL açma |

## Hızlı Başlangıç (Windows)

```bash
# 1) Flutter'ı kurun: https://docs.flutter.dev/get-started/install/windows
cd jarvis
flutter pub get

# 2) Tarayıcıda test (hızlı önizleme):
flutter run -d chrome

# 3) Android telefonda test (kabloyla, geliştirici modu açık):
flutter run -d <cihaz_id>

# Kalite kontrol:
flutter analyze
flutter test
```

> El feneri, parlaklık, takvim gibi native özellikler tarayıcıda çalışmaz; Android/iOS'ta çalışır.

## iPhone'a Kurulum (Windows'tan, ücretsiz)

> **İyi haber:** Apple Developer Program üyeliği ($99/yıl) GEREKMEZ. Ücretsiz Apple ID ile sideload yapılabilir. Tek sınır: uygulama her **7 günde bir yeniden imzalanmalı** (Sideloadly'de 1 tıklık iş) ve aynı anda en fazla 3 uygulama kurulabilir. Tüm özellikler (mikrofon, kamera, rehber, konum, takvim, bildirimler) ücretsiz profilde de çalışır.

### Yol 1 — GitHub Actions + Sideloadly (önerilen, tamamen ücretsiz)

1. Repo'yu GitHub'a push edin → **Actions** sekmesi → "iOS Unsigned IPA Build" → "Run workflow".
2. Build bitince **jarvis-unsigned-ipa** artefaktını indirin (sağ altta "Artifacts").
3. Windows'a **Sideloadly** kurun: https://sideloadly.io
4. iPhone'u USB ile bağlayın, iTunes/Apple Devices yüklü olsun (https://support.apple.com/downloads/apple-devices).
5. Sideloadly'de `.ipa`yı seçin, **Apple ID + şifreni** girin (2FA açıksa app-specific password üretin: https://appleid.apple.com → "Sign-In and Security" → "App-Specific Passwords").
6. "Start" → ilk seferde Apple ID'nize yönetici şifresiniz istenir (sadece izin için). iPhone'a otomatik kurulur.
7. Telefonda: **Ayarlar > Genel > VPN ve Cihaz Yönetimi** → geliştirici profiline dokun → **Güven**.
8. 7 gün dolunca: telefonu tekrar bağlayıp Sideloadly'de aynı `.ipa`yı tekrar kurun (ayarların kaybolmaması için "Try anyway" seçmeyin; önceki kurulumun üzerine kurar).

### Yol 2 — Codemagic (Apple Developer Program'lılar için)

1. GitHub'a repo'yu push edin.
2. https://codemagic.io → "Add application" → bu repo'yu seçin.
3. App Store Connect API anahtarı oluşturun: https://appstoreconnect.apple.com/access/api → "+" → **App Manager** izni → indirilen `.p8` dosyasının içeriğini Codemagic'e (App Store Connect integration) girin.
4. Codemagic'te şu environment group'larını ekleyin: `app_store_credentials` (App Store Connect API anahtarı), `certificate_credentials` (`CERTIFICATE_PRIVATE_KEY` = `.p8` içeriği).
5. `codemagic.yaml` dosyasındaki `BUNDLE_ID: com.jarvis.jarvis` değerini bırakın (Apple Developer Portal'da bu bundle ID'yi kaydedin).
6. Build çalıştırın → imzalı `.ipa` iner. Windows'ta `.ipa`'yı iPhone'a kurmak için:
   - **Macintosh**: Apple Configurator 2 (App Store'dan) ile kurun, veya
   - **Windows**: [iMazing](https://imazing.com) ile kurun, veya
   - Cihazınızı bir Mac'e bağlayıp Finder > Cihazlar > Uygulamalar'a `.ipa` sürükleyin.

### Yol 3 — Gerçek Mac

Mac'iniz varsa: `flutter build ipa --release --export-options-plist=export_options.plist` → `build/ios/ipa/` klasöründeki `.ipa`'yı Finder ile kurun.

## Ayarlar (Uygulama İçi)

- **Sağlayıcı seçimi:** OpenAI / Anthropic / Gemini (chat modelleri varsayılan: gpt-4o-mini, claude-3-5-sonnet, gemini-2.0-flash — model adını elle de değiştirebilirsiniz).
- **API anahtarları:** Ayarlar sekmesinden girilir, cihazda saklanır (SharedPreferences). ⚠️ Anahtar cihazda düz metin durur; kendi anahtarınız olduğundan risk size aittir.
- **STT:** Cihaz içi (ücretsiz) / Whisper (OpenAI anahtarı) / Gemini ses.
- **TTS:** Sistem sesi / OpenAI Jarvis sesi (onyx).
- **Kullanıcı adı:** "Efendim" yerine kendi isminiz.

## Örnek Komutlar

- "Merhaba Jarvis" / "Saat kaç?"
- "El fenerini aç" / "Parlaklığı yüzde 40 yap"
- "Pil durumu ne?"
- "Ne görüyorsun?" (kamera açılır, fotoğraf çekilir, AI anlatır)
- "10 dakika sonra çayı hatırlat" / "5 dakika zamanlayıcı kur"
- "Yarın saat 14:00'te toplantı ekle"
- "Pepper'ı ara" / "Rhodey'e 'Geldim' yaz" (kişi rehberden bulunur)
- "Hava nasıl?" / "Neredeyim?"

## iOS Kısıtları (Apple'ın kuralları — dürüst liste)

Apple, üçüncü parti uygulamaların şunları yapmasını **yasaklar**: Wi-Fi/Bluetooth kapatma, sistem ses seviyesi değiştirme, arka planda SMS gönderme, Rahatsız Etmeyin açma, diğer uygulamaları yönetme. Jarvis bu işleri **telefonun kendi onay ekranlarıyla** yapar (arama, mesaj taslağı gibi). "Her şeyi kontrol" ancak jailbreak (önerilmez) veya Siri Shortcuts otomasyonlarıyla kısmen mümkündür.

## Yol Haritası (native geliştirme gerektirenler)

- [ ] HomeKit (akıllı ev) — native Swift plugin gerektirir
- [ ] Siri Kısayollarını çalıştırma — `siri_shortcuts` native paketi
- [ ] "Jarvis" uyandırma kelimesi — sürekli mikrofon dinleme (batarya etkisi)
- [ ] Mesajlaşma uygulamalarının gerçekten gönderilmesi — iOS izin vermez, kalıcı çözüm yok

## Proje Yapısı

```
lib/
├── main.dart                     # Uygulama girişi, 5 sekmeli gezinme
├── config/theme.dart             # Jarvis teması (koyu + neon)
├── services/
│   ├── settings_service.dart     # Sağlayıcı/anahtar/model ayarları
│   └── ai/
│       ├── llm_client.dart       # OpenAI/Anthropic/Gemini + tool calling döngüsü + görüntü analizi
│       ├── tool_executor.dart    # Gerçek cihaz/uygulama araçları
│       ├── tools.dart            # Araç şemaları (function calling tanımları)
│       └── speech_service.dart   # STT (cihaz/Whisper/Gemini) + TTS (sistem/OpenAI)
├── viewmodels/
│   ├── jarvis_viewmodel.dart     # Kök ViewModel
│   └── chat_viewmodel.dart       # Sohbet durumu + ses akışı
└── views/
    ├── home_screen.dart          # Merkez
    ├── chat_screen.dart          # Jarvis sohbet (sesli arayüz)
    ├── agent_screen.dart         # Telefon ajani (cihaz kontrolleri)
    ├── communication_screen.dart # Rehber / arama / mesaj
    └── settings_screen.dart      # API anahtarları ve tercihler
```

Native taraf: iOS `AppDelegate.swift` (el feneri MethodChannel `jarvis/torch`) + Android `MainActivity.kt` (aynı kanal) — üçüncü parti plugin gerekmeden yazıldı.
