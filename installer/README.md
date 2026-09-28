# Windows quraşdırıcı

`installer\\install.bat` faylına iki dəfə klikləyin. GUI Node.js 18+, npm, ilkin qovluqları və `.env` faylını hazırlayır, `npm ci` işlədir, istəyə görə AI API key saxlayır və Desktop shortcut yaradır.

Shortcut əvvəlcə `http://localhost:3456/health` yoxlayır. Server işləyirsə dashboard birbaşa açılır. İşləmirsə arxa planda `npm start` başladılır, server hazır olduqdan sonra `http://localhost:3456` avtomatik açılır.


## Testdən sonra təmizləmə

`installer\\uninstall.bat` faylına iki dəfə klikləyin. Açılan GUI mənbə kodunu saxlayaraq `node_modules`, `.env`, `config`, `data`, `logs`, `temp`, `uploads` və Desktop shortcut-u silir.

Node.js ayrıca yalnız onu bu installer quraşdırıbsa seçim kimi göstərilir. Beləliklə digər Node.js layihələrinin mühiti təsadüfən silinmir.

Yenidən test üçün:

`install.bat → test → uninstall.bat → install.bat`
