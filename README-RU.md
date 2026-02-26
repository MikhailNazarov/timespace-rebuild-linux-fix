# Time Space Rebuild (時空重構) — Linux Fix

> Данный скрипт предназначен для владельцев лицензионной копии игры
> и служит исключительно для обеспечения совместимости с Linux.

Игра не поддерживает Linux официально. Для запуска через Proton нужно:
1. Установить 32-битный Vulkan-драйвер (игра 32-битная)
2. Расшифровать и перемуксировать внутриигровые видео (HLS + AES-128 не поддерживается Wine Media Foundation)
3. Добавить параметр запуска в Steam

## Требования

- Steam с Proton (GE-Proton или Proton Experimental)
- Для AMD GPU: `lib32-vulkan-radeon` (Arch) или аналог для вашего дистрибутива
- Для Intel GPU: `lib32-vulkan-intel` (Arch) или аналог для вашего дистрибутива
- Для NVIDIA GPU: `lib32-nvidia-utils`
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

Ubuntu/Debian (AMD):
```bash
sudo apt install mesa-vulkan-drivers:i386
```

### 2. Параметры запуска в Steam

Steam → ПКМ по игре → Свойства → Общие → Параметры запуска:
```
PROTON_MEDIA_USE_GST=1 %command%
```

### 3. Запустить скрипт модификации видео

Скрипт автоматически:
- Находит папку игры в Steam
- Создает бэкап оригинальных видеофайлов
- Расшифровывает .ts сегменты (AES-128)
- Собирает сегменты в чистые MPEG-TS файлы
- Заменяет .m3u8 файлы на готовые видео

```bash
chmod +x fix-videos.sh
./fix-videos.sh
```

Для указания нестандартного пути к игре:
```bash
./fix-videos.sh /path/to/steamapps/common/時空重構
```

### 4. Запустить игру

Готово. Видео должны воспроизводиться корректно.

## Откат изменений

Бэкап сохраняется в `CommonVideoClips.bak` рядом с `CommonVideoClips`.
Для отката:
```bash
GAME="$HOME/.local/share/Steam/steamapps/common/時空重構/時空重構/時空重構_Data/StreamingAssets"
rm -rf "$GAME/CommonVideoClips"
mv "$GAME/CommonVideoClips.bak" "$GAME/CommonVideoClips"
```

## Суть проблемы

Внутриигровые видео хранятся в формате HLS (M3U8 + .ts сегменты) с AES-128 шифрованием.
Wine/Proton Media Foundation не поддерживает HLS. Вместо видео показывается тестовая таблица (цветные полосы).

Скрипт расшифровывает сегменты и собирает их в обычные MPEG-TS файлы,
которые Media Foundation (через GStreamer backend) может воспроизвести.
