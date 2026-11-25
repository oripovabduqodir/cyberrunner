# ROADMAP.md — CYBER RUNNER Rivojlantirish Rejasi

Loyiha bosqichma-bosqich amalga oshiriladi. Har bir bosqich foydalanuvchi tasdig‘idan so‘ng bajariladi.

## 1-BOSQICH: Loyiha infratuzilmasi va sozlamalar (Joriy bosqich)
- [x] Mavjud Godot loyihasini tekshirish
- [x] Loyiha papkalari tuzilmasini yaratish (`assets`, `scenes`, `scripts`, `shaders`, `resources`)
- [x] Asosiy hujjatlarni yaratish (`AGENTS.md`, `HANDOFF.md`, `GAME_DESIGN.md`, `ROADMAP.md`)
- [x] Godot loyiha sozlamalarini 1280×720 Landscape va Compatibility renderer rejimiga moslash

## 2-BOSQICH: Bosh qahramon (Player) harakati va fizikasi (Yakunlandi)
- [x] Input Map sozlamalarini yaratish (klaviatura va sensorli ekran uchun)
- [x] `Player` sahnasi va `CharacterBody2D` asosidagi harakat skripti
- [x] Yugurish, sakrash, gravitatsiya, coyote time, jump buffer, double jump va dash mexanikalari
- [x] Test maydonchasida (`test_level.tscn`) fizika va kamerani sozlash

## 3-BOSQICH (UI): Asosiy Menyu, Settings, Level Select va UI Dizayni (Yakunlandi)
- [x] `cyberpunk_theme.tres` va qayta ishlatiladigan `CyberButton` komponenti
- [x] Parallax fon, tuman, neon miltillash va yomg‘ir zarrachalari (`cyber_background.tscn`)
- [x] Asosiy menyu (`main_menu.tscn`) va Exit tasdiqlash oynasi
- [x] Settings oynasi (`settings_menu.tscn`), `AudioServer` buslari (`Master`, `Music`, `SFX`) va `user://settings.cfg`
- [x] Level Select oynasi (`level_select.tscn`) va sahnalar o‘rtasida Fade In / Fade Out o‘tish (`SceneTransition`)

## 4-BOSQICH (LEVEL 01): Neon City Darajasi (Yakunlandi)
- [x] Yaxshilangan Cyberpunk jangchisi sprite va zarracha effektlari (`DashTrail`, `LandParticles`)
- [x] `neon_city_tileset.tres` (`TileSet`) va `TileMapLayer` asosidagi modulli xarita
- [x] 4 qatlamli `Parallax2D` shahar foni va sanoat/shahar dekoratsiyalari
- [x] Modulli `Checkpoint` va `SecurityGate` tizimlari
- [x] `neon_city.tscn` (9216px, 5 ta hudud) va menyu integratsiyasi

## 5-BOSQICH: Jang va qurol tizimi
- [ ] Sog‘liq (Health) va zarar (Damage/Hitbox/Hurtbox) komponentlari
- [ ] Qurol va o‘q otish tizimi (Object Pooling bilan)
- [ ] Qahramonning zarar olishi, qayta tiklanishi va o‘lim holati

## 4-BOSQICH: Dushmanlar va to‘siqlar
- [ ] Asosiy dushman robot AI (patrul, aniqlash, hujum)
- [ ] Uchuvchi dron yoki minora dushmani
- [ ] Xavfli to‘siqlar (lazerlar, tuzoqlar, tushish zonalari)

## 5-BOSQICH: 1-daraja — Neon City
- [ ] TileSet va TileMapLayer sozlash
- [ ] Parallax fon qatlamlari
- [ ] Neon City darajasini loyihalash va test qilish

## 6-BOSQICH: 2-daraja (Secret Laboratory) va 3-daraja (Final Battle)
- [ ] Secret Laboratory darajasi va uning o‘ziga xos mexanikalari
- [ ] Final Battle arenasi va Markaziy Boshqaruv Tizimi (Boss) jangi
- [ ] Darajalar o‘rtasida o‘tish tizimi

## 7-BOSQICH: UI/UX, HUD va Mobil boshqaruv
- [ ] Asosiy menyu, Pauza menyusi, Game Over va G‘alaba ekranlari
- [ ] O‘yin ichidagi HUD (HP bar, ball/progress)
- [ ] Android uchun ekran tugmalari (TouchScreenButton)

## 8-BOSQICH: Audio, Effektlar va Eksport
- [ ] Cyberpunk audio va SFX integratsiyasi
- [ ] Yengil neon shaderlar va zarracha effektlari
- [ ] Mobil unumdorlikni profillash va optimizatsiya
- [ ] Android (APK/AAB) va Windows eksport sozlamalari
