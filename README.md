# YouTube AI Agent

**Müəllif:** Abdulla Cavadov

YouTube kanalı üçün mövzu araşdırmasından başlayaraq ssenari, səsləndirmə, vizual materiallar, video montajı, metadata optimallaşdırması, yoxlama, planlaşdırma, yayımlama və analitika mərhələlərini bir iş axınında birləşdirən açıq mənbəli AI agent sistemi.

## Əsas imkanlar

- **Avtomatlaşdırılmış istehsal:** mövzu araşdırması, strategiya, ssenari, səsləndirmə, vizuallar, thumbnail və SEO.
- **İnsan təsdiqi:** keyfiyyət, fakt yoxlaması, media hüquqları və yayımdan əvvəl təsdiq mərhələləri.
- **YouTube inteqrasiyası:** OAuth, planlaşdırma, metadata yoxlaması və yayımlama.
- **Çoxsaylı AI provayderləri:** Gemini, OpenAI, OpenRouter, Kimi, MiMo, GLM və digər OpenAI-compatible endpoint-lər.
- **Video istehsalı:** Seedance, MiniMax H3, Gemini Omni Flash, Kling, Wan və yerli FFmpeg əsaslı fallback.
- **Bərpa edilə bilən istehsal:** hər mərhələ SQLite-da saxlanılır və yarımçıq proseslər son mərhələdən davam etdirilə bilir.
- **Scene Repair Studio:** ayrı-ayrı səhnələri yenidən yaratmaq, narrasiyanı bərpa etmək, səhnələri sıralamaq və lisenziyalı media ilə əvəz etmək.
- **Shorts Repurposing Studio:** mövcud uzun videodan 9:16 Shorts hazırlamaq.
- **Research & Provenance:** faktiki iddiaları mənbələrlə əlaqələndirmək və yoxlamaq.
- **Discoverability Preflight:** məzmunun axtarış və AI görünürlüğü üzrə məsləhət xarakterli audit.
- **Analitika və öyrənmə:** CTR, retention, engagement, watch time və kanal tarixçəsinə əsaslanan təsdiq-gated tövsiyələr.
- **Audience Engagement:** şərhlərin sinifləndirilməsi və insan təsdiqi tələb edən cavab qaralamaları.
- **Controlled Growth Experiments:** title və thumbnail variantlarını idarə olunan eksperimentlərlə ölçmək.
- **Outcome & ROI:** KPI, büdcə, gəlir və məlum istehsal xərclərini birlikdə izləmək.

## Windows quraşdırılması

Developer olmayan istifadəçi üçün Windows quraşdırması artıq GUI ilə aparılır.

1. GitHub-dan layihəni ZIP kimi endirin və çıxarın.
2. `installer/install.bat` faylına iki dəfə klikləyin.
3. Installer Node.js 18+ tələbini yoxlayacaq və lazım gəlsə Node.js LTS quraşdırmağı təklif edəcək.
4. AI provayderini və API key-i istəyə görə daxil edin.
5. `npm ci`, ilkin qovluqlar, `.env` və Desktop shortcut avtomatik hazırlanacaq.
6. Desktop-dakı **YouTube AI Agent** shortcut-u server işləyirsə birbaşa dashboard-u açır; server işləmirsə `npm start` başladır, `/health` hazır olduqdan sonra `http://localhost:3456` açılır.

Əlavə texniki məlumat: `installer/README.md`.

## Sürətli başlanğıc

Tələblər:

- Node.js 18+
- Google hesabı və YouTube Data API məlumatları
- Ən azı bir AI mətn provayderinin API açarı
- FFmpeg (ffmpeg-static vasitəsilə layihəyə daxil edilir)
- Xarici DarkzSEO checkout-u ayrıca sınaqdan keçirilirsə Python 3.9+

Quraşdırma:

`bash
git clone https://github.com/abdullacavadov/youtube_ai_agent.git
cd youtube_ai_agent
npm install
npm run walkthrough
npm start
`

Sonra brauzerdə http://localhost:3456 ünvanını açın.

Daha qısa quraşdırma axını üçün:

`bash
npm run setup
`

Ətraflı mühit dəyişənləri üçün .env.example faylına baxın.

## İstehsala hazırlığın yoxlanılması

Dashboard-da **Production readiness** bölməsindən yoxlama işə salına bilər. Sistem canlı mətn və səsləndirmə sorğularını, YouTube kanalına çıxışı, müvəqqəti MP4 yaradılmasını və növbədəki upload metadata-sını yoxlayır.

Bu yoxlama avtomatik olaraq YouTube videosu yaratmır və yayımlamır. Müvəqqəti probe faylları yoxlamadan sonra silinir. Ödənişli şəkil və video yoxlamaları ayrıca təsdiq tələb edir.

## Yarımçıq istehsala davam

Hər istehsal mərhələsi SQLite checkpoint-i yaradır. Provayder timeout verərsə və ya tətbiq yenidən başladılarsa, dashboard saxlanılmış mərhələni göstərir. **Resume** seçimi ilə proses ilk tamamlanmamış mərhələdən davam etdirilə bilər.

Saxlanılmış fayllar yenidən istifadə edilməzdən əvvəl yoxlanılır; itmiş və ya yararsız artefaktlar yenidən yaradılır.

## Səhnə təmiri

**Scene Repair Studio** vasitəsilə:

- səhnə mətnini və prompt-u dəyişmək;
- səhnənin sırasını dəyişmək;
- işlək səhnəni kilidləmək;
- lisenziyalı media ilə əvəz etmək;
- yalnız seçilmiş səhnəni yenidən yaratmaq;
- yalnız narrasiyanı yenidən yaratmaq mümkündür.

Narrasiya, fakt yoxlaması, hüquqlar və səhnə vəziyyəti ayrıca izlənilir. Natamam və ya uğursuz narrasiya yayıma buraxılmır.

## Shorts

Təsdiqlənmiş uzun videodan **Shorts Repurposing Studio** ilə 3 qısa video qaralaması yaratmaq mümkündür. Mənbə səhnələri, zaman aralıqları, başlıq, təsvir, tag-lər və review sübutları qorunur.

9:16 render üçün blur-canvas, center-crop və stacked-focus layout-ları mövcuddur. Mövcud video və narrasiya yenidən istifadə edildiyinə görə standart workflow yeni image, video və TTS krediti tələb etmir.

## Araşdırma və mənbələr

**Evidence Desk** vasitəsilə:

1. mənbələri əlavə etmək;
2. faktiki iddiaları qeyd etmək;
3. iddianı onu dəstəkləyən mənbə ilə əlaqələndirmək;
4. mənbəni yoxlamaq;
5. lazım olduqda reviewer qeydi əlavə etmək mümkündür.

Təsdiqlənməmiş faktiki iddialar yayıma mane olan vəziyyət yarada bilər. Mənbə tələb etməyən məzmun ayrıca qeyd olunur.

## Discoverability

Məhsulda **Discoverability Preflight** adlı məsləhət xarakterli audit mövcuddur. Audit canonical content package üzərində işləyir və nəticələri SQLite-da saxlayır.

Nəticələrdə engine/schema versiyası, severity, stabil rule ID-lər və ayrı-ayrı finding-lər qorunur. Yanlış pozitivlər reviewer səbəbi ilə rədd edilə bilər.

Xarici DarkzSEO checkout-u ilə test:

`bash
DARKZSEO_PATH=../darkzseo/darkzseo.py npm start
`

Xarici adapter shell-siz Python prosesindən istifadə edir və JSON stdin/stdout interfeysi ilə işləyir.

## Autonomous Channel Operator

Dashboard-dakı **Autonomous operator** kanalın məqsədini, auditoriyasını, kontent sütunlarını, paylaşım tezliyini, uğur metrikasını və məhdudiyyətlərini qəbul edir.

Operator:

- YouTube trend və rəqib siqnallarını araşdırır;
- son kanal mövzularını analiz edir;
- mənbələrlə işarələnmiş editorial plan yaradır;
- planlaşdırılmış videoları strategiya → ssenari → thumbnail → SEO → istehsal → workflow mərhələlərindən keçirir.

Avtonomluq insan təsdiqi mərhələlərini keçmir. Fakt yoxlaması, media hüquqları və approval gate-ləri qüvvədə qalır.

## Analitika və öyrənmə

Yayımdan sonra 24 saatlıq və 7 günlük real performans snapshot-ları toplana bilər. Sistem CTR, retention, engagement, watch time, format, uzunluq, hook və title üslubunu kanalın öz tarixçəsi ilə müqayisə edir.

Tövsiyələr avtomatik tətbiq edilmir. Operator onları ayrıca təsdiqləməlidir.

**Controlled Growth Experiments** title və thumbnail variantlarını məhdud zaman pəncərəsində test edir. Eksperimentin sonunda control versiyası bərpa edilir və nəticənin tətbiqi ayrıca təsdiq tələb edir.

## Audience Engagement

**Engagement** bölməsi son videoların şərhlərini sinifləndirir:

- mövzu;
- sentiment;
- suallar;
- spam/scam/toxic işarələri.

Agent şərhləri silmir və gizlətmir. Cavablar yalnız qaralama kimi hazırlanır və yayımdan əvvəl insan təsdiqi tələb olunur.

## Outcome & ROI

Kanal strategiyasında əsas KPI, hədəf, ölçmə müddəti, aylıq istehsal büdcəsi və valyuta müəyyən edilə bilər.

Mövcud olduqda sistem:

- subscriber dəyişimini;
- watch hour;
- monetizasiya sübutlarını;
- məlum istehsal xərclərini;
- net revenue;
- ROI göstəricilərini saxlayır.

Məlumat yoxdursa, sistem onu sıfır kimi göstərmir; **unavailable** vəziyyəti saxlanılır.

## Layihə strukturu

`text
youtube_ai_agent/
├── agents/          # AI agent-lər
├── config/          # konfiqurasiya və nümunə credential faylları
├── database/        # SQLite sxemi və data layer
├── dashboard/       # veb dashboard
├── mcp/             # MCP konfiqurasiyaları
├── schedules/       # avtomatlaşdırılmış cədvəllər
├── utils/           # AI, media, analitika və workflow xidmətləri
├── assets/          # demo və digər resurslar
├── examples/        # yoxlanılmış nümunə nəticələri
├── reports/         # hesabatlar
├── scripts/         # köməkçi skriptlər
├── index.js         # əsas Express server
├── setup.js         # quraşdırma axını
└── walkthrough.js   # interaktiv walkthrough
`

## Troubleshooting

| Problem | Həll |
|---|---|
| AI provider credential yoxdur | credentials:setup ilə ən azı bir provayder əlavə edin |
| FFmpeg tapılmır | npm install işlədin və ya FFMPEG_PATH təyin edin |
| Video simulated görünür | Startup capability check nəticələrini yoxlayın |
| Publish queue işləmir | Planlaşdırılmış vaxtı və queue log-larını yoxlayın |
| YouTube quota bitib | Google Cloud Console quota göstəricilərini yoxlayın |
| Content generation uğursuzdur | API açarlarını, kreditləri və logs qovluğunu yoxlayın |
| Publishing uğursuzdur | YouTube OAuth-u yenidən təsdiqləyin və video formatını yoxlayın |

Debug rejimi:

`bash
NODE_ENV=development DEBUG_MODE=true npm start
`

## Contributing

Dəyişiklik göndərərkən bir PR-da bir əsas mövzu saxlamaq, lazımsız package-lock.json dəyişikliklərindən qaçmaq və lint/test yoxlamalarını keçirmək tövsiyə olunur.

`bash
npm install
npm test
npm run lint
`

## License

MIT — ətraflı məlumat üçün LICENSE faylına baxın.

## Müəllif

**Abdulla Cavadov**

GitHub: https://github.com/abdullacavadov

---

Bu layihə qanuni məzmun istehsalı üçün nəzərdə tutulub. YouTube Terms of Service və Community Guidelines tələblərinə əməl edin.
