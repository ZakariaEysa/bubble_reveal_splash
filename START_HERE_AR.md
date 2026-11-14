# باكدج bubble_reveal_splash

اسبلاش Flutter بستارة بابل بتتفتح، واللوجو بيبدأ صغير في نص الشاشة ويكبر
لحد حجمه الطبيعي. الباكدج مستقلة عن Your Seat ومن غير اعتماديات تشغيل خارج Flutter.

## التثبيت بعد النشر

```sh
flutter pub add bubble_reveal_splash
```

```dart
import 'package:bubble_reveal_splash/bubble_reveal_splash.dart';
import 'package:flutter/material.dart';

BubbleSplash(
  logo: Image.asset('assets/logo.png', width: 200),
  backgroundColor: Colors.white,
  style: const BubbleStyle(
    colors: [Colors.teal, Colors.cyan, Colors.lightBlueAccent],
    count: 75,
  ),
  logoAnimation: const BubbleLogoAnimation(
    startScale: 0,
    endScale: 1,
    startOpacity: 1,
  ),
  onCompleted: () {
    // هنا بتحدد التنقل أو الخطوة اللي بعد الاسبلاش.
  },
)
```

ضيف الصورة في assets بتاعت تطبيقك. حط الاسبلاش في مكان له عرض وارتفاع محددين
زي body بتاع Scaffold. اللوجو ممكن يكون صورة أو نص أو أي Widget، بما فيها SVG
عن طريق باكدج تختارها في تطبيقك.

## تجربة المثال المحلي

```powershell
cd E:\packages\bubbles\example
flutter pub get
flutter run -d chrome
```

المثال فيه LUMA وثيمين SOL وNOVA، وتحكم في العدد والحجم والمدة والاتجاه
والتأخير والظلال والشكل وطبقة اللوجو، مع تشغيل وإيقاف وعكس وسحب التقدم.

قبل النشر تقدر تستخدم المسار المحلي في pubspec.yaml:

```yaml
dependencies:
  bubble_reveal_splash:
    path: E:/packages/bubbles
```

الاسم البرمجي بقى `bubble_reveal_splash` وملف الدخول
`lib/bubble_reveal_splash.dart`؛ اسم المجلد المحلي فضل `bubbles`.

في [README](https://github.com/ZakariaEysa/bubble_reveal_splash#readme) أمثلة لكل
إعدادات الألوان والـ gradients والخلفية واللوجو والظلال والحدود والأشكال
والأحجام والحركة والـ callbacks والـ AnimationController والـ custom builders.
الافتراضي بيحترم إعداد تقليل الحركة في الجهاز، وبيُلغي المؤقتات عند إزالة الاسبلاش.

دليل النشر للمؤلف في `PUBLISHING.md`.
