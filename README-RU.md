# Time Space Rebuild (時空重構) — Linux Fix

> Данный скрипт предназначен для владельцев лицензионной копии игры
> и служит исключительно для обеспечения совместимости с Linux.

Игра не поддерживает Linux официально. Через Proton запускается, но внутриигровые видео
(HLS + AES-128 шифрование) не воспроизводятся — вместо них тестовая таблица (цветные полосы) или вылет.

Скрипт расшифровывает и перемуксирует видео в обычные MPEG-TS файлы, которые GE-Proton может воспроизвести.

## Требования

- Steam с **GE-Proton** (установить через [ProtonUp-Qt](https://github.com/DavidoTek/ProtonUp-Qt) или вручную с [GE-Proton releases](https://github.com/GloriousEggroll/proton-ge-custom/releases))
- 32-битный Vulkan-драйвер (игра 32-битная)
- `ffmpeg` и `openssl` (обычно уже установлены)

## Установка

### 1. Установить 32-битный Vulkan-драйвер

Arch Linux (AMD):
```bash
sudo pacman -S lib32-vulkan-radeon
```

Arch Linux (Intel):
```bash
sudo pacman -S lib32-vulkan-intel
```

Arch Linux (NVIDIA):
```bash
sudo pacman -S lib32-nvidia-utils
```

Ubuntu/Debian (AMD/Intel):
```bash
sudo apt install mesa-vulkan-drivers:i386
```

Ubuntu/Debian (NVIDIA):
```bash
# Узнать версию драйвера: nvidia-smi | head -3
sudo apt install libnvidia-gl-560:i386
```

### 2. Запустить скрипт модификации видео

Скрипт автоматически:
- Находит папку игры в Steam
- Создаёт бэкап оригинальных видеофайлов
- Расшифровывает .ts сегменты (AES-128)
- Собирает сегменты в чистые MPEG-TS файлы
- Заменяет .m3u8 плейлисты на готовые видео

```bash
git clone https://github.com/MikhailNazarov/timespace-rebuild-linux-fix.git
cd timespace-rebuild-linux-fix
chmod +x fix-videos.sh
./fix-videos.sh
```

Для нестандартного пути к игре:
```bash
./fix-videos.sh /path/to/steamapps/common/時空重構
```

### 3. Выбрать GE-Proton и запустить

В Steam: ПКМ по игре → Свойства → Совместимость → отметить «Принудительно использовать выбранное средство совместимости» → выбрать **GE-Proton**.

## Откат изменений

Бэкап сохраняется в `CommonVideoClips.bak` рядом с `CommonVideoClips`.
Для отката:
```bash
GAME="$HOME/.local/share/Steam/steamapps/common/時空重構/時空重構/時空重構_Data/StreamingAssets"
rm -rf "$GAME/CommonVideoClips"
mv "$GAME/CommonVideoClips.bak" "$GAME/CommonVideoClips"
```

Также можно использовать «Проверить целостность файлов игры» в Steam.

## Суть проблемы

Игра использует [AVProVideo](https://renderheads.com/products/avpro-video/) для воспроизведения видео через Windows Media Foundation.
Внутриигровые видео хранятся в формате HLS (`.m3u8` плейлисты + `.ts` сегменты), зашифрованные AES-128.

Реализация Media Foundation в Wine/Proton не справляется с таким форматом:
- **Proton Experimental**: вместо видео — тестовая таблица 320×240 (цветные полосы SMPTE)
- **GE-Proton**: вылет при попытке воспроизвести зашифрованный HLS

Скрипт расшифровывает сегменты и собирает их в обычные MPEG-TS файлы,
которые Media Foundation в GE-Proton воспроизводит нативно.
