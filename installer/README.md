# Windows quraşdırıcı

`installer\\install.bat` faylına iki dəfə klikləyin. GUI artıq CLI walkthrough-un 6 mərhələsini Windows wizard kimi təqdim edir:

1. Sistem — Node.js 18+, FFmpeg, qovluqlar və database hazırlığı
2. AI provider — Gemini, OpenAI, OpenRouter, Kimi, MiMo və GLM; API key və model
3. Video provider — Local slideshow, Seedance, MiniMax H3, Gemini Omni, Kling və Wan
4. YouTube — Client ID/Secret və istəyə görə avtomatik OAuth
5. Kanal və content — channel adı, posting frequency, target audience, privacy və post vaxtı
6. Yekun — seçilmiş konfiqurasiyanın yoxlanması və quraşdırmanın tamamlanması

Quraşdırıcı konfiqurasiyanı layihənin mövcud `CredentialManager` və SQLite database formatına yazır. Local slideshow seçimi xarici video krediti tələb etmir.

Shortcut əvvəlcə `http://localhost:3456/health` yoxlayır. Server işləyirsə dashboard birbaşa açılır. İşləmirsə arxa planda `npm start` başladılır, server hazır olduqdan sonra `http://localhost:3456` avtomatik açılır.

## Testdən sonra təmizləmə

`installer\\uninstall.bat` faylına iki dəfə klikləyin. Açılan GUI mənbə kodunu saxlayaraq `node_modules`, `.env`, `config`, `data`, `logs`, `temp`, `uploads` və Desktop shortcut-u silir.

Node.js ayrıca yalnız onu bu installer quraşdırıbsa seçim kimi göstərilir. Beləliklə digər Node.js layihələrinin mühiti təsadüfən silinmir.

Yenidən test üçün:

`install.bat → test → uninstall.bat → install.bat`
