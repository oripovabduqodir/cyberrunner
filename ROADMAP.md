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

## 5-BOSQICH: Jang va qurol tizimi (Yakunlandi)
- [x] Sog‘liq (`HealthComponent`, 100 HP, i-frames, knockback, flash, death) va Energiya (`EnergyComponent`, 100 EN, Dash sarfi va tiklanish)
- [x] `PlasmaPistol` (20 dmg, 12/48 o‘q, 0.25s cooldown, 1.2s reload, Object Pooling) va `CyberBlade` (35 dmg, 0.5s cooldown)
- [x] `EnemyBase` (State Machine, Line-of-Sight) va 3 ta dushman: `PatrolRobot`, `AttackDrone`, `SecurityTurret`
- [x] `Pickup` tizimi (`HealthPack`, `AmmoPack`, `EnergyCell`), `CombatHUD` va `GAME OVER` oynasi
- [x] `neon_city.tscn` integratsiyasi (7 Patrol Robot, 4 Attack Drone, 3 Security Turret, pickuplar)

## 5.1-BOSQICH: Jang Boshqaruvi va Nishon Tizimi (Yakunlandi)
- [x] 360° Mouse Aiming (`PlasmaPistol`, `CyberBlade`) va mustaqil qurol yo‘nalishi
- [x] Neon `Crosshair` (`crosshair.tscn`) va UI ustida otishni bloklash
- [x] Yaxshilangan PC boshqaruvi (`LMB/J` avtomatik otish, `RMB/K` qilich, `R/F` reload, `F6` restart)
- [x] Mobil uchun ixtiyoriy `AimAssist` (`aim_assist.gd`) arxitekturasi va dushman balansi

## 4-BOSQICH: Dushmanlar va to‘siqlar
- [ ] Asosiy dushman robot AI (patrul, aniqlash, hujum)
- [ ] Uchuvchi dron yoki minora dushmani
- [ ] Xavfli to‘siqlar (lazerlar, tuzoqlar, tushish zonalari)

## 5-BOSQICH: 1-daraja — Neon City
- [ ] TileSet va TileMapLayer sozlash
- [ ] Parallax fon qatlamlari
- [ ] Neon City darajasini loyihalash va test qilish

## 6-BOSQICH: 2-daraja (Secret Laboratory) va 3-daraja (Final Battle) (Yakunlandi)
- [x] `LevelProgressManager` Autoload va `user://progress.cfg` progress saqlash tizimi
- [x] Modulli tuzoqlar (`LaserTrap`, `ToxicLiquid`, `ElectricTrap`), `MovingPlatform`, `KeycardPickup`, `SecurityDoor`
- [x] `EliteRobot` (120 HP, 25 dmg, 300 score) va `secret_laboratory.tscn` (10880px, 6 hudud)
- [x] `OmegaXBoss` (1000 HP, 3 faza, Plasma/Laser/Ground Slam/Drone Summoning) va `final_battle.tscn`
- [x] `CombatHUD` Boss Health Bar, `NEXT LEVEL` va `GAME COMPLETED` oynalari hamda `LevelSelect` integratsiyasi

## 7-BOSQICH: Mobil Boshqaruv, Pause Menu va Unumdorlik Optimizatsiyasi (Yakunlandi)
- [x] `MobileInputManager` Autoload, `VirtualJoystick` va multi-touch `MobileActionButton` (`FIRE`, `JUMP`, `DASH`, `SLASH`, `RELOAD`, `PAUSE`)
- [x] `MobileControls` (`mobile_controls.tscn`) va `DisplayServer.get_display_safe_area()` Safe Area moslashuvi
- [x] `AimAssist` yangilanishi (`EnemyBase` + `OmegaXBoss`, anti-jitter, `TargetIndicator`)
- [x] `PauseMenu` (`pause_menu.tscn`, `P` tugmasi, mobil `||` tugmasi, Android Back, inline `SettingsMenu`)
- [x] `SettingsManager` & `SettingsMenu` kengaytirildi (`Mobile Controls Preview`, `Auto Aim`, `Touch Opacity/Size`, `FPS Limit`)
- [x] Audio va Android eksport tayyorlik auditi o‘tkazildi

## 8.1-BOSQICH: Professional Grafik va Vizual Yangilash (Yakunlandi)
- [x] `player_cyber_warrior.png` 64×64 formatga va 10 ta animatsiyaga (`idle`, `run`, `jump`, `fall`, `dash`, `shoot`, `melee`, `reload`, `hurt`, `death`) ko‘tarildi
- [x] `lab_bg.png` va `tower_bg.png` 1280×720 parallax fonlari, `NeonCity` nam yuzadagi neon akslar va `OmegaXBoss` 3 fazali vizual effektlari
- [x] `ASSET_CREDITS.md` yaratildi va barcha sahnalar Godot 4.7.2 konsolda tekshirildi

## 8.1.1-BOSQICH: Professional Character and Weapon Asset Integration (Yakunlandi)
- [x] `3 Cyborg` (48×48) sprite varaqlaridan 11 ta animatsiya (`idle`, `run`, `jump`, `double_jump`, `fall`, `dash`, `shoot`, `melee`, `reload`, `hurt`, `death`) `player_sprite_frames.tres` va `player.tscn` ga integratsiya qilindi
- [x] `PlasmaPistol` va `Projectile` CraftPix qurol (`plasma_pistol_gun.png`), muzzle effekti (`plasma_muzzle_fx.png`) va o‘q (`plasma_bullet.png`) bilan yangilandi; 360° nishon va Mobile Auto Aim saqlandi
- [x] `CYBER_RUNNER_Graphics_Reference/` `.gitignore` ga qo‘shildi va `ASSET_CREDITS.md` CraftPix litsenziya havolasi bilan yangilandi

## 8.1.2-BOSQICH: Neon City Professional Environment Overhaul (Yakunlandi)
- [x] `neon_city.tscn` 5 qatlamli `Parallax2D` tizimi (`Warped City` CC0 `skyline-a/b`, `buildings-bg`, `near-buildings-bg`, `Free Industrial Zone` silueti va oldingi qatlam) bilan yangilandi
- [x] `neon_city_tileset.tres` 32×32 `Free Industrial Zone` plitkalari (`Street`, `Rooftop`, `Bridge`, `Hazard`, `Box1`, `Fence1`) bilan yangilandi; mavjud collision shakllari va 9216px geometriya saqlandi
- [x] Barcha 5 hudud (`Spawn Area`, `City Streets`, `Rooftops`, `Industrial Zone`, `Security Gate`) Warped City neon belgilari, antennalar, uchuvchi transport vositalari va sanoat obyektlari bilan bezatildi; `Camera2D.zoom = Vector2(1.2, 1.2)` ga sozlandi

## 8.1.3-BOSQICH: Secret Laboratory Professional Environment Overhaul (Yakunlandi)
- [x] `secret_laboratory.tscn` 5 qatlamli `Parallax2D` tizimi (`Power Station` Night `1..5.png`) bilan yangilandi
- [x] `lab_tileset.tres` 32×32 `Power Station` (`Tileset.png`) plitkalari bilan yangilandi; mavjud 10880px geometriya va collision saqlandi
- [x] 6 ta laboratoriya hududi `bio_tank`, `reactor_unit`, animatsiyali `Screen1/2` monitorlari, quvurlar va miltillovchi ogohlantirish chiroqlari bilan bezatildi
- [x] `MovingPlatform`, `KeycardPickup`, `SecurityDoor`, `LaserTrap` va `ToxicLiquid` (pufakcha zarralari) vizual yangilandi; `Camera2D.zoom = Vector2(1.2, 1.2)` ga sozlandi

## 8.1.4-BOSQICH: Final Battle and OMEGA-X Boss Professional Visual Overhaul (Yakunlandi)
- [x] `final_battle.tscn` 5 qatlamli to‘q binafsha-qizil `Parallax2D` tizimi va `tower_tileset.tres` (32×32 zirhli pol va `IndustrialTile_74/75` ko‘priklar) bilan yangilandi
- [x] 4 ta hudud (`Tower Entrance`, `Defense Corridor`, `AI Control Center`, `Boss Arena`) reaktorlar, terminallar, ogohlantirish chiroqlari va `ArenaLockDoor` bilan bezatildi; `Camera2D.zoom = Vector2(1.15, 1.15)` ga sozlandi
- [x] `OmegaXBoss` 3 fazali vizual effektlar (`CoreGlow`, `PhaseSparks`, `SlamParticles`, `DeathBurst`, yengil `CameraShake`) bilan kuchaytirildi; 1000 HP va jang mexanikasi saqlandi

## 8.1.5-BOSQICH: Professional Enemies and Combat Effects Integration (Yakunlandi)
- [x] `AttackDrone` CraftPix `Drone 3` (`drone_idle`, `drone_fire`, `drone_death` — 48×48 kadrlar) bilan yangilandi; 40 HP, 10 dmg, 150 score saqlandi
- [x] `SecurityTurret` Warped City CC0 `turret-1..6` va `enemy-explosion-1..6` bilan yangilandi; 80 HP, 20 dmg, 200 score saqlandi
- [x] `Projectile` dushman snaryadi (`enemy-shot-1.png`) va zarba portlashi (`shot-hit-1.png`) Warped City CC0 effektlari bilan yangilandi; Object Pooling saqlandi

## 8.1.6-BOSQICH: Professional UI, Main Menu and HUD Overhaul (Yakunlandi)
- [x] `cyberpunk_theme.tres` (`#080B16`, `#101525`, `#00E5FF`, `#FF007F`, burchakli kiberpank panellar) va `CyberBackground` (Warped City CC0 skyline + uchuvchi transportlar) yangilandi
- [x] `MainMenu` (`HeroShowcase` Cyborg + `CREDITS` tugmasi), `CreditsMenu` (`credits_menu.tscn/.gd`) va `LevelSelect` (real sektor preview rasmlari + `COMPLETED/UNLOCKED/LOCKED`) yangilandi
- [x] `CombatHUD` (`WeaponIcon`, silliq HP tween, `<25%` qizil ogohlantirish, `RELOAD!` indikatori, Boss faza ranglari), `SettingsMenu` (`RESET DEFAULTS`) va `PauseMenu` (`GAME PAUSED`) yangilandi

## 8.1.7-BOSQICH: Final Graphics Polish and Visual Quality Overhaul (Yakunlandi)
- [x] `CyberBackground` da shahar fonining vertikal takrorlanishi `Parallax2D` (faqat gorizontal `repeat_size`) orqali bartaraf etildi; transportlar logotip va tugmalarga xalaqit bermaydigan zonaga ko‘chirildi
- [x] `MainMenu` da Cyborg ostiga metall tom platformasi (`HeroPlatform`), chap tomonga `MenuBackdrop` kontrasti va yumshoqroq glitch animatsiyasi (`±2.5px`, `4.2s`) qo‘shildi
- [x] `SecretLaboratory` fon yorqinligi muvozanatlashtirildi va barcha `113` ta PNG resurs auditi (`18` ta ishlatilmayotgan eski fayl) o‘tkazildi

## 8.1.8-BOSQICH: Professional Robot and Boss Asset Integration (Yakunlandi)
- [x] `PatrolRobot` CraftPix `Free-Sci-Fi-Antagonists` `3/` (96×96, `Idle`, `Walk`, `Attack1`, `Hurt`, `Death`) bilan yangilandi; `60 HP`, `15 dmg`, `100 score` va raycastlar saqlandi
- [x] `EliteRobot` CraftPix `Free-Sci-Fi-Antagonists` `2/` (96×96, `Idle`, `Walk`, `Special` warn, `Attack1`, `Hurt`, `Death`, `1.6x` og‘ir zirhli korpus) bilan yangilandi; `120 HP`, `25 dmg`, `300 score` saqlandi
- [x] `AttackDrone` (`Drone 3`) va `SecurityTurret` (`Warped City`) 2D side-scroller formatiga mosligi sababli saqlandi; `Frost_Guardian_FREE_v1.0` litsenziya fayli yo‘qligi sababli integratsiya qilinmadi (`omega_x.png` saqlandi)

## 8.1.9-BOSQICH: Professional OMEGA-X Boss Asset Integration (Yakunlandi)
- [x] `Frost_Guardian_FREE_v1.0` (`chierit`, CC BY 4.0) paketidan 53 ta original 192×128 shaffof PNG kadr (`idle` 6, `walk` 10, `attack_1` 14, `take_hit` 7, `death` 16) `assets/enemies/boss/omega_x/` ga joylashtirildi
- [x] `resources/omega_x_sprite_frames.tres` da 9 ta animatsiya (`idle`, `walk`, `plasma_attack`, `laser_charge`, `laser_fire`, `ground_slam`, `hurt`, `phase_transition`, `death`) faqat bepul kadrlardan kombinatsiya qilindi
- [x] `shaders/omega_x_cyber.gdshader` va `omega_x.tscn/.gd` orqali 3 fazali kiberpank palitra (Defense cyan, Attack magenta-red, Overload orange-red), yadro pulsatsiyasi, lazer telemetriyasi, zarba hit-flash va ikki marta mukofot berilishidan himoya joriy etildi; `1000 HP`, `5000 score` va barcha mexanikalar saqlandi
- [x] `ASSET_CREDITS.md`, `credits_menu.tscn`, `ROADMAP.md` va `HANDOFF.md` CC BY 4.0 atributsiyasi bilan yangilandi

## 8.1.10-BOSQICH: OMEGA-X Boss AI, Combat Behavior and Gameplay Fix (Yakunlandi)
- [x] `FinalBattle` sahnasidagi node tartibi sababli `_player_ref == null` bo‘lib qolishi `_ensure_player_ref()` (`call_deferred` + dinamik guruh/`find_child` qidiruvi) orqali bartaraf etildi
- [x] Boss State Machine (`_action_serial`, `action_timer` watchdog, burilish gisterezisi) bilan tuzatilib, uchala fazada uzluksiz ta’qib (`walk`) va hujum sikli tiklandi
- [x] `ContactArea` (tana ichida xavfsiz turishni to‘xtatuvchi `15 dmg` kontakt zarba + cooldown) va `MeleeHitbox` (yaqin masofa `Cleave` hujumi, `20/24 dmg`) qo‘shildi; `LaserArea` `offset_left = 12.0` ga yaqinlashtirildi
- [x] Real `final_battle.tscn` darajasida avtomatik jangovar test (`verify_omega_combat.gd`) bilan barcha 3 faza, Plasma, Laser, Drone, Ground Slam, Player HP kamayishi, Checkpoint Retry va `5000` ball / `GAME COMPLETED` tasdiqlandi

## 8.2-BOSQICH: Audio, Eksport va Yakuniy Release
- [ ] Cyberpunk audio va SFX integratsiyasi
- [ ] Yengil neon shaderlar va zarracha effektlari
- [ ] Mobil unumdorlikni profillash va optimizatsiya
- [ ] Android (APK/AAB) va Windows eksport sozlamalari
