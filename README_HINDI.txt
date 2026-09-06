राठौड़ तेली समाज रतलाम — मैट्रिमोनियल ऐप
==========================================

Gemini वाले कोड में ये समस्याएँ थीं:
- लाइनें बीच में कट गई थीं (compile नहीं होता)
- फील्ड नाम मेल नहीं खाते थे (name / full_name, isAdmin / is_admin)
- FlutLab daily limit, Storage billing, web emulator काला स्क्रीन
- google-services.json और applicationId मेल नहीं खा रहे थे

यह फोल्डर पूरा, सही Dart कोड है।

------------------------------------------
Firebase में 4 काम (एक बार)
------------------------------------------
1. console.firebase.google.com → अपना प्रोजेक्ट rathore-teli-ratlam
2. Authentication → Sign-in method → Email/Password ON करें
3. Firestore Database → Create (asia-south1, test mode ठीक है)
4. Project settings → Your apps → Android ऐप
   Package name वही लिखें जो android/app/build.gradle में applicationId है
   (उदाहरण: com.mycompany.rathoretelisamajratlam)
   फिर google-services.json डाउनलोड करें और android/app/ में रखें।

एडमिन बनाने के लिए:
Firestore → users → अपने यूज़र का डॉक्यूमेंट खोलें
isAdmin फील्ड Boolean = true कर दें।
लॉगआउट-लॉगिन करने पर ऊपर एडमिन आइकन दिखेगा।

Firestore नियम (शुरू के लिए test mode):
allow read, write: if request.auth != null;

बाद में सख्त नियम लगाएँ।

------------------------------------------
APK कैसे बनाएँ — सबसे आसान तरीका
------------------------------------------
FlutLab फ्री प्लान पर रोज़ की लिमिट खत्म हो जाती है। इसलिए:

विकल्प A — GitHub Actions (फ्री, बिना लैपटॉप पर Flutter इंस्टॉल)
1. github.com पर नया Public repo बनाएँ
2. इस पूरे फोल्डर की फाइलें अपलोड करें
   (lib/main.dart, pubspec.yaml, और android फोल्डर + google-services.json)
3. फाइल बनाएँ: .github/workflows/build.yml

name: Build APK
on: [push, workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: Rathore-Teli-App
          path: build/app/outputs/flutter-apk/app-release.apk

4. Actions टैब → ग्रीन टिक → Artifacts से APK डाउनलोड

विकल्प B — अपने लैपटॉप पर Flutter इंस्टॉल करके:
flutter pub get
flutter build apk --release

------------------------------------------
ऐप कैसे चलता है
------------------------------------------
- रजिस्टर / लॉगिन (ईमेल + पासवर्ड)
- बायोडाटा जोड़ें → status = Pending
- होम पर सिर्फ Approved प्रोफाइल दिखती हैं (वर / वधू टैब)
- एडमिन पेंडिंग लिस्ट से Approve या Delete करता है
- फोटो के लिए अभी Firebase Storage नहीं (ब्लिंकिंग कार्ड नहीं लगेगा)
  बाद में फोटो URL टेक्स्ट फील्ड जोड़ सकते हैं

Play Store बाद में: Google Play Console ₹2100 एक बार।
शुरुआत में WhatsApp ग्रुप में APK बाँट सकते हैं।
