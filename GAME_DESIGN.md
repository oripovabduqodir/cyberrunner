# GAME_DESIGN.md — CYBER RUNNER

## 1. Umumiy Konsepsiya
- **O‘yin nomi:** CYBER RUNNER
- **Janr:** 2D Action Platformer
- **Grafik uslub:** Cyberpunk Pixel Art
- **Platformalar:** Android va Windows
- **Ekran o‘lchami:** 1280×720 (Landscape)
- **Renderer:** Compatibility (`gl_compatibility`)
- **Ranglar palitrasi:**
  - Asosiy fon: Qora / To‘q ko‘k-qora (`#0A0A12`)
  - Urg‘u ranglari: Neon ko‘k (`#00F0FF`), Binafsha (`#8A2BE2`), Pushti (`#FF007F`)

## 2. O‘yin Ssenariysi
2077-yilda futuristik megapolis to‘liq robotlar va avtonom mudofaa tizimlari nazoratiga o‘tgan. Shahar aholisi xavf ostida qolgan bir paytda, kibernetik jihatdan kuchaytirilgan bosh qahramon (Cyber Runner) robotlar qo‘shiniga qarshi kurashib, xavfli texnologik to‘siqlardan o‘tishi va shaharni boshqarayotgan **Markaziy Boshqaruv Tizimi**ni yo‘q qilishi kerak.

## 3. Darajalar Tuzilmasi
O‘yin uchta asosiy darajadan iborat:
1. **Neon City** — Kiberpank uslubidagi tungi shahar ko‘chalari, neon reklama taxtalari, tomlar ustidagi sakrashlar, patrul robotlar va lazerli to‘siqlar.
2. **Secret Laboratory** — Robotlar ishlab chiqariladigan va boshqariladigan yashirin yerosti laboratoriyasi. Murakkab platformalar, xavfsizlik kameralari, dronlar va tuzoqlar.
3. **Final Battle** — Markaziy boshqaruv tizimining yadrosi. Yakuniy Boss jangi va o‘yinning kulminatsion nuqtasi.

## 4. Asosiy O‘yin Mexanikalari (Reja)
- **Harakat:** Chap/o‘ngga yugurish, sakrash (coyote time va jump buffering bilan), dash (tez siljish).
- **Jang tizimi:** Energetik qurol (otish) va/yoki yaqin masofa zarbasi, dushmanlarga zarar yetkazish va HP tizimi.
- **Dushmanlar:** Patrul robotlar, uchuvchi dronlar, himoya minoralari va Yakuniy Boss.
- **To‘siqlar:** Lazer nurlari, elektr tuzoqlar, harakatlanuvchi platformalar.
- **Boshqaruv:**
  - **Windows:** Klaviatura (WASD / Strelkalar, Space, J/K yoki Sichqoncha) va Gamepad.
  - **Android:** Ekrandagi qulay virtual sensor tugmalar (Virtual Joystick / D-Pad va Action tugmalari).

## 5. Vizual va Audio Yo‘nalish
- **Vizual:** Aniq piksel grafika (`Nearest` filtrlash), parallax fon qatlamlari, neon rangli zarracha effektlari (sparks, dash trail).
- **Audio:** Synthwave / Cyberpunk uslubidagi fon musiqasi, lazer va zarba ovozlari.
