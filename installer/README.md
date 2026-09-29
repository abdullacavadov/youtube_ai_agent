# Windows quraşdırıcı

installer\\install.bat faylına iki dəfə klikləyin.

## Install

Installer yalnız deployment üçün lazım olan komponentləri quraşdırır:

1. Node.js 18+ yoxlanılır; yoxdursa istifadəçidən Node.js LTS quraşdırılması soruşulur.
2. Agent işləyirsə dayandırılır.
3. npm ci --no-audit --no-fund ilə dependency-lər quraşdırılır.
4. installer\\launcher.ps1 və installer\\launch.bat yaradılır (repo-da yoxdur, yalnız uğurlu quraşdırmadan sonra əlavə olunur).
5. Desktop shortcut yaradılır və launcher.ps1-ə bağlanır.

**Installer heç bir tətbiq konfiqurasiyası tələb etmir və yazmır.**

Install zamanı bunlar soruşulmur və saxlanılmır:

- AI provider
- AI API key və model
- Video provider və API key
- YouTube Client ID / Client Secret
- OAuth
- Channel məlumatları
- Content settings

Bu məlumatlar tətbiqin öz **Settings** bölməsindən konfiqurasiya edilməlidir.

Installer .env, config, data, database, credentials və digər istifadəçi məlumatlarını yaratmır və dəyişdirmir.

## Uninstall

installer\\uninstall.bat faylına iki dəfə klikləyin.

Uninstall yalnız:

- node_modules
- installer\\launch.bat və installer\\launcher.ps1
- Desktop-dakı YouTube AI Agent shortcut-u
- yalnız bu installer tərəfindən quraşdırılıbsa və istifadəçi seçərsə Node.js

üzərində əməliyyat aparır.

Aşağıdakılara **toxunulmur**:

- .env
- config
- data
- logs
- temp
- uploads
- database faylları
- credentials / OAuth token-ləri
- generated content
- source code və layihə faylları

Beləliklə uninstall → install etdikdə istifadəçi konfiqurasiyası qorunur.

## Launcher

Desktop shortcut install zamanı yaradılan installer\\launcher.ps1 faylını işə salır. Server hazırdırsa dashboard açılır; hazır deyilsə npm start arxa planda başladılır və http://localhost:3456 açılır.
