# AGENTS.md — CYBER RUNNER Loyiha Qoidalari va Arxitekturasi

Ushbu hujjat **CYBER RUNNER** o‘yinini ishlab chiqishda barcha agentlar va dasturchilar amal qilishi shart bo‘lgan qoidalar, texnik standartlar va loyiha tuzilmasini belgilaydi.

## 1. Loyiha haqida qisqacha ma’lumot
- **O‘yin nomi:** CYBER RUNNER
- **Janr:** 2D Action Platformer
- **Dvigatel:** Godot 4 (GDScript)
- **Grafik uslub:** Cyberpunk Pixel Art
- **Asosiy ranglar:** Qora, neon ko‘k, binafsha, pushti
- **Platformalar:** Android va Windows
- **Ekran o‘lchami:** 1280×720 (Landscape)
- **Renderer:** Compatibility (`gl_compatibility`)

## 2. Ishlash qoidalari
1. Loyihani **bosqichma-bosqich** rivojlantiramiz.
2. **Faqat foydalanuvchi tasdiqlagan bosqichni** bajar.
3. Keyingi bosqichga **mustaqil ravishda o‘tma**.
4. Ishlayotgan tizimlarni **sababsiz o‘zgartirma**.
5. Kodlar **modulli, tushunarli va optimallashtirilgan** bo‘lsin.
6. **Mobil qurilmalarning unumdorligini** har doim hisobga ol.
7. Har bir vazifa oldidan `AGENTS.md` va `HANDOFF.md` fayllarini o‘qi.
8. Har bir bajarilgan vazifadan keyin `HANDOFF.md` faylini yangila.
9. O‘zgartirilgan fayllar va aniqlangan xatolar haqida aniq ma’lumot ber.
10. Foydalanuvchi bilan **o‘zbek tilida** muloqot qil.

## 3. GDScript va Arxitektura Standartlari
- **Statik tiplash:** Barcha o‘zgaruvchilar, parametrlar va qaytish qiymatlari uchun aniq tiplardan foydalaning (`var speed: float = 200.0`, `func take_damage(amount: int) -> void:`).
- **Modullilik:** Har bir skript bitta aniq mas’uliyatga ega bo‘lsin (masalan: harakat, qurol, sog‘liq komponenti, AI).
- **Signallar (Signals):** Tugunlar (nodes) o‘rtasidagi bog‘liqlikni kamaytirish uchun signallardan foydalaning (`EventBus` yoki lokal signallar).
- **Resurslar:** O‘yin ma’lumotlari (qurol statistikasi, dushman parametrlari) uchun `Resource` klasslaridan (`.tres`) foydalaning.
- **Pixel Art sozlamalari:** Piksel san’ati tiniq ko‘rinishi uchun tekstura filtrini `Nearest` holatida saqlang.

## 4. Mobil Unumdorlik Qoidalari
- Tez-tez yaratiladigan obyektlar (o‘qlar, zarrachalar, effektlar) uchun imkon qadar **Object Pooling** qo‘llang.
- `_process()` va `_physics_process()` ichida og‘ir hisob-kitoblar va obyekt qidirish (`get_node()`, `find_child()`) ishlarini bajarmang; `@onready` dan foydalaning.
- Shaderlar va yorug‘lik effektlarini (glow/bloom) Compatibility renderer va mobil GPU imkoniyatlariga mos holda yengil tuting.
- Audio fayllarni mobil uchun optimallashtirilgan formatlarda (`.ogg` / `.wav`) saqlang.

## 5. Loyiha Papkalar Tuzilmasi
- `assets/` — barcha grafik va audio resurslar:
  - `characters/` — bosh qahramon spraytlari va animatsiyalari
  - `enemies/` — dushman robotlar va boss spraytlari
  - `backgrounds/` — parallax fon rasmlari
  - `tilesets/` — darajalar uchun tilesetlar
  - `audio/` — musiqa va ovoz effektlari (SFX)
  - `fonts/` — piksel va kiberpank shriftlar
- `scenes/` — `.tscn` sahnalar:
  - `player/` — bosh qahramon sahnasi va komponentlari
  - `enemies/` — dushmanlar sahnalari
  - `levels/` — o‘yin darajalari (Neon City, Secret Laboratory, Final Battle)
  - `ui/` — menyular, HUD, mobil boshqaruv tugmalari
  - `weapons/` — qurollar va o‘qlar
- `scripts/` — umumiy GDScript fayllari, autoloadlar va komponentlar
- `shaders/` — `.gdshader` fayllari (neon, CRT, glitch, hit flash)
- `resources/` — `.tres` ma’lumot resurslari
